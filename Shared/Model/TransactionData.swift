//
//  TransactionData.swift
//  SPENT
//
//  Created by Eric Nims on 7/3/21.
//

import Foundation
import GRDB

struct TransactionData: Identifiable, FetchableRecord, Decodable, Hashable {
    var id: Int64 {
        get {
            transaction.id!
        }
    }
    
    var tags: [Tag]
    var source: Bucket?
    var destination: Bucket?
    var transaction: Transaction
    var splitMembers: [Transaction]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(transaction)
    }
}
