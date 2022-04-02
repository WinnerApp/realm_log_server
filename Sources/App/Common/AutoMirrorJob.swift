//
//  AutoMirrorJob.swift
//  
//
//  Created by 张行 on 2022/4/1.
//

import Foundation
import Vapor
import FluentKit

/// 自动执行镜像的任务
class AutoMirrorJob {
    let githubApi:GithubApi
    let giteeApi:GiteeApi
    let app:Application
    let wxHook:WeiXinWebHooks
    init(app:Application) throws {
        giteeApi = try GiteeApi()
        githubApi = try GithubApi()
        self.app = app
        self.wxHook = try WeiXinWebHooks()
    }
    /// 执行任务
    func start() {
        app.logger.info("准备执行自动任务")
        Task {
            /// 将当前状态更改为可以执行工作
            await autoMirrorStatus.start()
            do {
                /// 开始进行制作镜像
                try await mirror()
            } catch(let e) {
                if let abort = e as? Abort {
                    app.logger.error("自动化任务失败: \(abort.reason)")
                    /// 制作过程中发生了报错 将错误上传给
                    wxHook.sendContent(abort.reason, client: app.client)
                }
            }
            
            let canRun = await autoMirrorStatus.canRun
            guard canRun else {
                 return
            }
            start()
        }
    }
    
    func mirror() async throws {
        /// 等待制作镜像的任务完成
        while true {
            app.logger.info("查询正在等待制作的任务")
            let waitingMirror = try await Mirror.query(on: app.db).filter(\.$isExit == false).first()
            /// 如果没有正在制作的任务则退出等待
            guard let waitingMirror = waitingMirror else {
                app.logger.info("当前没有等待制作任务")
                break
            }
            app.logger.info("正在制作\(waitingMirror.origin)的镜像")
            app.logger.info("查询制作是否完毕")
            let isExit = try await giteeApi.checkRepoExit(url: waitingMirror.mirror, in: app.client)
            app.logger.info("isExit: \(isExit)")
            guard !isExit else {
                let ymlFilePath = try getYmlFilePath(url: waitingMirror.origin)
                app.logger.info("正在删除 \(ymlFilePath) 文件")
                /// 删除文件
                try await githubApi.deleteYml(fileName: ymlFilePath, in: app.client)
                app.logger.info("制作完毕 更新数据库数据")
                waitingMirror.isExit = true
                try await waitingMirror.update(on: app.db)
                continue
            }
            app.logger.info("等待制作完毕 等待30秒继续查询")
            let _ = try await app.threadPool.runIfActive(eventLoop: app.eventLoopGroup.next(), {
                sleep(30)
            }).get()
        }
        app.logger.info("按照创建时间获取第一条等待执行镜像的数据")
        guard let stack = try await MirrorStack.query(on: app.db).sort(\.$create).first() else {
            app.logger.info("没有任务 暂停自动任务")
            await autoMirrorStatus.stop()
            return
        }
        /// 获取到需要镜像的仓库地址
        let originUrl = stack.url
        app.logger.info("准备制作任务:\(originUrl)")
        /// 获取仓库的组织或者用户名称 比如 Vapor
        guard let src = repoOriginPath(from: originUrl) else {
            app.logger.error("\(originUrl)中获取组织或者用户失败")
            throw Abort(.custom(code: 10000, reasonPhrase: "\(originUrl)中获取组织或者用户失败"))
        }
        /// 获取仓库名称 比如 Vapor
        guard let name = repoNamePath(from: originUrl) else {
            app.logger.error("\(originUrl)中获取仓库名称失败")
            throw Abort(.custom(code: 10000, reasonPhrase: "\(originUrl)中获取仓库名称失败"))
        }
        /// 生成对应的 Gtihub Action配置文件名称
        let ymlFile = try getYmlFilePath(url: originUrl)
        /// 查询用户拥有的组织信息
        app.logger.info("正在查询用户组织列表")
        let orgs = try await giteeApi.getUserOrg(client: app.client)
        /// 默认组织名称的数字
        var index = 0
        /// 默认的组织名称
        var orgName = "spm_mirror"
        while true {
            /// 准备制作镜像的地址
            let mirrorPath = "https://gitee.com/\(orgName)/\(name)"
            app.logger.info("准备制作镜像:\(mirrorPath)")
            /// 获取准备制作的镜像是否已经存在
            if let mirror = try await Mirror.query(on: app.db).filter(\.$mirror == mirrorPath).first() {
                app.logger.error("镜像已经占用:\(mirror.origin)")
                /// 制作的镜像已经存在被其他占用 更换镜像组织
                index += 1
                orgName += "\(index)"
                continue
            }
            /// 判断当前的组织是否需要进行创建
            if !orgs.contains(where: {$0.name == orgName}) {
                /// 创建不存在的组织
                app.logger.info("正在创建组织:\(orgs)")
                try await giteeApi.createOrg(client: app.client, name: orgName)
            }
            app.logger.info("查询是否已经创建yml 文件")
            let ymlExit = try await githubApi.ymlExit(file: ymlFile, in: app.client)
            if !ymlExit {
                app.logger.info("\(ymlFile)不存在")
                /// 查询仓库是否是组织
                let isOrg = try await githubApi.isOrg(name: src, client: app.client)
                /// yml的内容
                let ymlContent = actionContent(src: src,
                                                   dst: orgName,
                                                   isOrg: isOrg,
                                                   repo: name,
                                                   mirror: name)
                app.logger.info("创建Github Action Yml")
                let createOK = try await githubApi.addGithubAction(fileName: ymlFile,
                                                                   content: ymlContent,
                                                                   client: app.client)
                guard createOK else {
                    app.logger.error("创建\(ymlFile)文件失败")
                    throw Abort(.custom(code: 10000, reasonPhrase: "创建\(ymlFile)文件失败"))
                }
            }
            let mirror = Mirror(origin: originUrl, mirror: mirrorPath)
            app.logger.info("保存镜像数据到数据库")
            try await mirror.save(on: app.db)
            app.logger.info("删除制作镜像队列")
            try await stack.delete(on: app.db)
        }
    }
}


actor AutoMirrorStatus {
    var canRun:Bool = false
    
    init() {}
    
    func start() {
        canRun = true
    }
    
    func stop() {
        canRun = false
    }
}


let autoMirrorStatus = AutoMirrorStatus()
