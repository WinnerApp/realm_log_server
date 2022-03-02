//
//  File.swift
//  
//
//  Created by 张行 on 2022/2/10.
//

import Foundation
import Vapor
import FluentKit

struct NetworkLogController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("network_log")
        group.post(use:create)
        group.get(use:all)
        
        group.post("list", use: createList)
    }
    
    func create(req:Request) async throws -> ResponseModel<String> {
        try NetworkLogValidaable.validate(content: req)
        let log = try req.content.decode(NetworkLog.self)
        try await log.create(on: req.db)
        return ResponseModel()
    }
    
    func createList(req:Request) async throws -> ResponseModel<String> {
        try CreateListRequestContent.validate(content: req)
        let content = try req.content.decode(CreateListRequestContent.self)
        guard !content.list.isEmpty else {
            throw Abort(.custom(code: 1, reasonPhrase: "list不能为空"))
        }
        await withThrowingTaskGroup(of: Void.self, body: { group in
            content.list.forEach { log in
                group.addTask {
                    try await log.create(on: req.db)
                }
            }
        })
        return ResponseModel()
    }
    
    func all(req:Request) async throws -> ResponseModel<[NetworkLog]> {
        let page = try await NetworkLog.query(on: req.db)
            .filter(\.$request.$method == "GET")
            .paginate(for: req)
        
        return ResponseModel(data: page.items,
                             page: page.metadata)
    }
}

struct CreateListRequestContent:Content, Validatable {
    let list:[NetworkLog]
    static func validations(_ validations: inout Validations) {
        validations.add(each: "list", required: true) { _, validations in
            NetworkLogValidaable.validations(&validations)
        }
    }
}

/// 验证提交的内容
struct NetworkLogValidaable: Validatable {
    static func validations(_ validations: inout Validations) {
        let timeMax = Int(Date.now.timeIntervalSince1970) * 1000
        /// 日志必须是一年以内的
        let timeMin = timeMax - 1_000 * 365 * 24 * 60 * 60
        validations.add("startTime",
                        as: Int.self,
                        is: .range(timeMin ... timeMax),
                        required: true)
        validations.add("endTime",
                        as: Int.self,
                        is: .range(timeMin ... timeMax),
                        required: true)
        
        validations.add("request",
                        required: true) { validations in
            validations.add("headers",
                            as: String.self,
                            is: .isJsonText,
                            required: true)
            validations.add("baseUrl",
                            as: String.self,
                            required: true)
            validations.add("extra",
                            as: String.self,
                            is: .isJsonText,
                            required: false)
            validations.add("method",
                            as: String.self,
                            is: .in(["GET","POST","PUT","DELETE","PATCH"]),
                            required: true)
            validations.add("path",
                            as: String.self,
                            is: !.empty,
                            required: true)
            validations.add("queryParameters",
                            as: String.self,
                            is: .isJsonText,
                            required: false)
            validations.add("responseType",
                            as: String.self,
                            is: !.empty,
                            required: false)
            validations.add("data",
                            as: String.self,
                            is: .isJsonText,
                            required: false)
            
        }
        
        validations.add("response", required: true) { validations in
            validations.add("data",
                            as: String.self,
                            is: .isJsonText,
                            required: false)
            validations.add("extra",
                            as: String.self,
                            is: .isJsonText,
                            required: false)
            validations.add("headers",
                            as: String.self,
                            is: .isJsonText,
                            required: true)
            validations.add("statusCode",
                            as: Int.self,
                            required: true)
            validations.add("statusMessage",
                            as: String.self,
                            required: true)
        }
        
    }
}

extension Validator {
    static var isJsonText:Validator<String> {
        return .init { data in
            guard let jsonData = data.data(using: .utf8) else {
                return ValidatorResults.NotJSONText(isJsonText: false)
            }
            guard let object = try? JSONSerialization.jsonObject(with: jsonData,
                                                            options: .fragmentsAllowed) else {
                return ValidatorResults.NotJSONText(isJsonText: false)
            }
            guard object is [String:Any] else {
                return ValidatorResults.NotJSONText(isJsonText: false)
            }
            return ValidatorResults.NotJSONText(isJsonText: true)
        }
    }
}



extension ValidatorResults {
    struct NotJSONText {
        let isJsonText:Bool
    }
}

extension ValidatorResults.NotJSONText: ValidatorResult {
    var isFailure: Bool { !isJsonText }
    var successDescription: String? { nil }
    var failureDescription: String? { isFailure ? "不是一个 JSON 字符串" : nil}
}

