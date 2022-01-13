//
//  Balance.swift
//  SPENT
//
//  Created by Eric Nims on 9/11/21.
//

import GRDB
import Foundation

struct TransactionBalance: Codable, Hashable, FetchableRecord {
    var transactionID: Int64
    var bucketID: Int64
    var ancestorID: Int64
    var postedRunning: Int?
    var availRunning: Int?
    
    static var databaseTableName: String = "transactionBalance"
    
    private enum CodingKeys: String, CodingKey {
        case transactionID = "id", bucketID = "Bucket", ancestorID = "Account", postedRunning = "pRunning", availRunning = "aRunning"
    }
}
