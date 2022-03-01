//
//  File.swift
//  
//
//  Created by 张行 on 2022/2/9.
//

import Foundation
import FluentKit
import Vapor

/// 客户端发送过来的网络模型
final class NetworkLog: Model, Content {
    
    static var schema: String { "network_log" }
    
    @ID(key: .id)
    var id:UUID?
    
    /// 网络发起的时间戳
    @Field(key: "start_time")
    var startTime:Int
    
    /// 网络结束的时间戳
    @Field(key: "end_time")
    var endTime:Int
    
    /// 请求的 Request 信息
    @Group(key: "request")
    var request:NetworkRequestLog
    
    /// 请求的 Response 信息
    @Group(key: "response")
    var response:NetworkResponseLog
    
    init() {}
    
}

/// 请求发送的 Request 数据
final class NetworkRequestLog: Fields, Content {
    /// Headers 的 JSON 字符串
    @Field(key: "headers")
    var headers:String
    
    /// 请求的基础域名
    @Field(key: "base_url")
    var baseUrl:String
    
    /// 额外的参数的 JSON 字符串
    @Field(key: "extra")
    var extra:String?
    
    /// 请求的方式
    @Field(key: "method")
    var method:String
    
    /// 请求的路径
    @Field(key: "path")
    var path:String
    
    /// 请求的参数的 JSON 字符串
    
    @Field(key: "query_parameters")
    var queryParameters:String?
    
    /// 返回的类型
    @Field(key: "response_type")
    var responseType:String?
    
    /// 请求数据的 JSON 字符串
    @Field(key: "data")
    var data:String?
    
    /// 默认初始化
    init() {}
    
}

/// 请求收到的 Response 数据
final class NetworkResponseLog: Fields, Content {
    /// Response 相应数据的 JSON 字符串
    @Field(key: "data")
    var data:String?
    
    /// Response 的额外数据
    @Field(key: "extra")
    var extra:String?
    
    /// Response 的头的 JSON 字符串
    @Field(key: "headers")
    var headers:String?
    
    /// Response 的 Code
    @Field(key: "status_code")
    var statusCode:Int
    
    /// Response 的 状态信息
    @Field(key: "status_message")
    var statusMessage:String
    

    /// 默认初始化
    init() {}
    
}

