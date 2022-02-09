//
//  File.swift
//  
//
//  Created by 张行 on 2022/2/9.
//

import Foundation
import FluentKit
import Vapor

final class NetworkLog: Model, Content {
    
    static var schema: String { "network_log" }
    
    @ID(key: .id)
    var id:UUID?
    
    /// 网络发起的时间戳
    @Field(key: "start_time")
    var startTime:TimeInterval?
    
    /// 网络结束的时间戳
    @Field(key: "end_time")
    var endTime:TimeInterval?
    
}
