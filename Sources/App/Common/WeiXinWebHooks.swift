//
//  WeiXinWebHooks.swift
//  
//
//  Created by 张行 on 2022/4/1.
//

import Foundation
import Vapor

/// 负责发送错误日志给微信 能够及时处理问题
struct WeiXinWebHooks {
    /// 微信接收的 WebHook地址
    let url:String
    init() throws {
        /// 从配置读取微信的 WebHook 地址
        guard let url = Environment.get("WEIXIN_HOOK") else {
            print("WEIXIN_HOOK 不存在")
            throw Abort(.expectationFailed)
        }
        self.url = url
    }
    /// 给微信机器人发送消息
    /// - Parameters:
    ///   - content: 发送内容
    ///   - client: 发送的链接终端
    func sendContent(_ content:String, client:Client) {
        print("\(url)")
        print("发送微信消息:\(content)")
        let messageString:[String:String] = ["content":content]
        let messageJson: [String: Any] = ["text":messageString,
                                          "msgtype":"text",]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: messageJson) else {
            return
        }
        guard let text = String(data: jsonData, encoding: .utf8) else {
            return
        }
        Task {
            let response = try await client.post(URI(string: url), beforeSend: { request in
                request.body = .init(string: text)
            })
            response.printLog()
        }
    }
}

struct WeiXinWebHookContent: Content {
    let msgType:String
    let text:TextContent
}

extension WeiXinWebHookContent {
    struct TextContent: Content {
        let content:String
    }
}
