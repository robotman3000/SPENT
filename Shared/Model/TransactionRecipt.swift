//
//  TransactionRecipts.swift
//  SPENT
//
//  Created by Eric Nims on 6/17/21.
//

import Foundation
import GRDB

struct TransactionRecipt: Identifiable, Codable, Hashable {
    var id: Int64?
    var transactionID: Int64
    var reciptID: Int64
    
    private enum CodingKeys: String, CodingKey {
        case id, transactionID = "TransactionID", reciptID = "ReciptID"
    }
}

extension TransactionRecipt {
    static let transaction = belongsTo(Transaction.self, key: "TransactionID")
    var transaction: QueryInterfaceRequest<Transaction> {
        guard id != nil else {
            return Transaction.none()
        }
        return Transaction.filter(id: transactionID)
    }
    
    static let recipt = belongsTo(Recipt.self, key: "ReciptID")
    var recipt: QueryInterfaceRequest<Recipt> {
        guard id != nil else {
            return Recipt.none()
        }
        return Recipt.filter(id: reciptID)
    }
}


// SQL Database support
extension TransactionRecipt: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "TransactionRecipts"
    
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
    
    // Define database columns from CodingKeys
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let transactionID = Column(CodingKeys.transactionID)
        static let reciptID = Column(CodingKeys.reciptID)
    }
}
