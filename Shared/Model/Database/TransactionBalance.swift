//
//  Balance.swift
//  SPENT
//
//  Created by Eric Nims on 9/11/21.
//

import GRDB

struct TransactionBalance: Codable, Hashable, FetchableRecord {
    var transactionID: Int64
    var bucketID: Int64
    var ancestorID: Int64
    var amount: Int
    var postedRunning: Int?
    var availRunning: Int?
    var date: Date
    
    static var databaseTableName: String = "transactionBalance"
    
    private enum CodingKeys: String, CodingKey {
        case transactionID = "tid", bucketID = "bid", ancestorID = "aid", amount = "amount", postedRunning = "pRunning", availRunning = "aRunning", date = "tdate"
    }
}
