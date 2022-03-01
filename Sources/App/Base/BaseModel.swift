//
//  BaseModel.swift
//  
//
//  Created by 张行 on 2022/2/14.
//

import Foundation
import Vapor

/// 相应的基本结构
final class BaseModel<T:Content>: Content {
    /// 信息
    final let message:String
    /// 响应Code
    final let code:Int
    /// 数据源
    final let data:T?
}
