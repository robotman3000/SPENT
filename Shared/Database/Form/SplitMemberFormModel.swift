//
//  SplitMemberFormModel.swift
//  SPENT
//
//  Created by Eric Nims on 6/8/22.
//

import GRDB
import SwiftUI

struct SplitMemberFormModel: Identifiable, Hashable {
    /// Random UUID for identifiable requirement; This is not the Split UUID from the database
    var id: UUID = UUID()
    var editStatus: EditStatus = .inMemory
    let splitUUID: UUID
    
    var split: SplitTransaction?
    var transaction: Transaction
    var amount: String = ""
    var bucket: Bucket?
    var memo: String = ""
    
    init(splitUUID: UUID){
        self.transaction = Transaction(id: nil, status: .Void, amount: 0, payee: "", memo: "", entryDate: Date(), postDate: nil, bucketID: nil, accountID: -1)
        self.editStatus = .inMemory
        self.splitUUID = splitUUID
    }
    
    init(withDatabase: Database, model: SplitTransaction) throws {
        self.split = model
        self.splitUUID = model.splitUUID
        let dbTransaction = try model.transaction.fetchOne(withDatabase)
        guard dbTransaction != nil else {
            throw FormInitializeError("Failed to load transaction for split member with id \(model.id.debugDescription)")
        }
        
        self.transaction = dbTransaction!
        self.amount = NSDecimalNumber(value: abs(transaction.amount)).dividing(by: 100).stringValue
        self.bucket = try self.transaction.bucket.fetchOne(withDatabase)
        self.memo = transaction.memo
        self.editStatus = .databaseClean
    }
    
    enum EditStatus {
        case databaseClean, databaseModified, databaseDeleted, inMemory, memoryDelete
    }
}
