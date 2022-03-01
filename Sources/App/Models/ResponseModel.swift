//
//  ResponseModel.swift
//  
//
//  Created by 张行 on 2022/2/28.
//

import Foundation
import Vapor

struct ResponseModel<T: Content>: Content {
    let code:Int
    let message:String
    let success:Bool
    let data:T?
    
    init(success message:String = "请求成功", data:T? = nil) {
        self.code = 200
        self.message = message
        self.success = true
        self.data = data
    }
    
    init(failure message:String, code:Int) {
        self.message = message
        self.code = code
        self.success = false
        self.data = nil
    }
}
