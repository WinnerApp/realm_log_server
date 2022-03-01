//
//  File.swift
//  
//
//  Created by 张行 on 2022/2/10.
//

import Foundation
import FluentKit

struct CreateNetworkLogMigrations: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(NetworkLog.schema)
            .id()
            .field("start_time", .int64)
            .field("end_time", .int64)
            .field("request_headers", .string)
            .field("request_base_url", .string)
            .field("request_extra", .string)
            .field("request_method", .string)
            .field("request_path", .string)
            .field("request_query_parameters", .string)
            .field("request_response_type", .string)
            .field("request_data", .string)
            .field("response_data", .string)
            .field("response_extra", .string)
            .field("response_headers", .string)
            .field("response_status_code", .int64)
            .field("response_status_message", .string)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(NetworkLog.schema).delete()
    }
}
