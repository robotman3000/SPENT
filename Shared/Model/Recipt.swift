//
//  Recipt.swift
//  SPENT
//
//  Created by Eric Nims on 6/17/21.
//

import Foundation
import GRDB

struct Recipt: Identifiable, Codable, Hashable {
    var id: Int64?
    var blob: Data
    
    private enum CodingKeys: String, CodingKey {
        case id, blob = "Blob"
    }
}

extension Recipt {
    static let transaction = hasOne(Transaction.self, through: hasOne(TransactionRecipt.self, key: "ReciptID"), using: TransactionRecipt.transaction)
    var transaction: QueryInterfaceRequest<Transaction> {
        request(for: Recipt.transaction)
    }
}


// SQL Database support
extension Recipt: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "Recipts"
    
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
    
    // Define database columns from CodingKeys
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let blob = Column(CodingKeys.blob)
    }
}
