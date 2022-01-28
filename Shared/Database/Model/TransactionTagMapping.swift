//
//  TransactionTags.swift
//  SPENT
//
//  Created by Eric Nims on 5/27/21.
//

import Foundation
import GRDB

struct TransactionTagMapping: Identifiable, Codable, Hashable {
    var id: Int64?
    var transactionID: Int64
    var tagID: Int64
}

extension TransactionTagMapping {
    static let transaction = belongsTo(Transaction.self, key: "TransactionID")
    var transaction: QueryInterfaceRequest<Transaction> {
        guard id != nil else {
            return Transaction.none()
        }
        return Transaction.filter(id: transactionID)
    }
    
    static let tag = belongsTo(Tag.self, key: "TagID")
    var tag: QueryInterfaceRequest<Tag> {
        guard id != nil else {
            return Tag.none()
        }
        return Tag.filter(id: tagID)
    }
}


// SQL Database support
extension TransactionTagMapping: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "TransactionTagMap"
    
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
    
    // Define database columns from CodingKeys
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let transactionID = Column(CodingKeys.transactionID)
        static let tagID = Column(CodingKeys.tagID)
    }
}
