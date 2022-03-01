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
            .field("request", .dictionary)
            .field("response", .dictionary)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(NetworkLog.schema).delete()
    }
}
