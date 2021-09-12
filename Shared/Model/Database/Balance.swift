//
//  Balance.swift
//  SPENT
//
//  Created by Eric Nims on 9/11/21.
//

import GRDB

struct Balance: Codable, Hashable, FetchableRecord {
    var tid: Int64
    var bid: Int64
    var aid: Int64
    var amount: Int
    var running: Int
    var tdate: Date
    
    static var databaseTableName: String = "balance"
}
