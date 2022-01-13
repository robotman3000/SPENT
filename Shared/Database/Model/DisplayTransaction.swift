//
//  DisplayTransaction.swift
//  SPENT
//
//  Created by Eric Nims on 1/11/22.
//

import GRDB
import Foundation

struct DisplayTransaction: Identifiable, Codable, Hashable, FetchableRecord {
    var id: Int64
    var sourceID: Int64?
    var destID: Int64?
    var memo: String?
    var payee: String?
    
    static let databaseUUIDEncodingStrategy = DatabaseUUIDEncodingStrategy.string
    var group: UUID?
    
    var type: Transaction.TransType = .Invalid
    var amount: Int
    var bucketID: Int64
    var accountID: Int64
    var date: Date
    var isAllocation: Bool
    var postedRunning: Int?
    var availRunning: Int?
    
    static var databaseTableName: String = "allTransactions"
    
    // id, status, sourcebucket, destbucket, memo, payee, group, v_type, amount, bucket, account, date, isallocation, postedrunning, availablerunning
    private enum CodingKeys: String, CodingKey {
        case id = "id", sourceID = "SourceBucket", destID = "DestBucket", memo = "Memo", payee = "Payee", group = "Group", type = "V_Type", amount = "Amount", bucketID = "Bucket", accountID = "Account", date = "Date", isAllocation = "isAllocation", postedRunning = "PostedRunning", availRunning = "AvailableRunning"
    }
}
