//
//  Transfer.swift
//  SPENT
//
//  Created by Eric Nims on 1/27/22.
//

import Foundation
import GRDB

struct Transfer: Identifiable, Codable, Hashable {
    var id: Int64?
    var sourceTransactionID: Int64
    var destinationTransactionID: Int64
}

extension Transfer {
    static let source = belongsTo(Transaction.self, key: "SourceTransactionID")
    var sourceTransaction: QueryInterfaceRequest<Transaction> {
        Transaction.filter(id: sourceTransactionID)
    }
    
    static let destination = belongsTo(Transaction.self, key: "DestinationTransactionID")
    var destinationTransaction: QueryInterfaceRequest<Transaction> {
        Transaction.filter(id: destinationTransactionID)
    }
}

// SQL Database support
extension Transfer: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "Transfers"
    
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
    
    // Define database columns from CodingKeys
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let sourceTransactionID = Column(CodingKeys.sourceTransactionID)
        static let destinationTransactionID = Column(CodingKeys.destinationTransactionID)
    }
}
