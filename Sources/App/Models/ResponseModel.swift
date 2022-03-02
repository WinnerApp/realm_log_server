//
//  ResponseModel.swift
//  
//
//  Created by 张行 on 2022/2/28.
//

import Foundation
import Vapor
import FluentKit

struct ResponseModel<T: Content>: Content {
    let code:Int
    let message:String
    let success:Bool
    let data:T?
    let page:PageMetadata?
    
    init(success message:String = "请求成功",
         data:T? = nil,
         page:PageMetadata? = nil) {
        self.code = 200
        self.message = message
        self.success = true
        self.data = data
        self.page = page
    }
    
    init(failure message:String, code:Int) {
        self.message = message
        self.code = code
        self.success = false
        self.data = nil
        self.page = nil
    }
}
