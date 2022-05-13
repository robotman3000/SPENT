//
//  AccountBalance.swift
//  macOS
//
//  Created by Eric Nims on 5/13/22.
//

import Foundation
import GRDB

struct AccountBalance: Decodable, FetchableRecord, TableRecord {
    let id: Int64
    let posted: Int
    let available: Int
    let allocatable: Int
    
//    static let account = belongsTo(Account.self)
//    static var databaseTableName: String = "AccountBalance"
}
