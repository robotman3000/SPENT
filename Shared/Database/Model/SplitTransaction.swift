//
//  Split.swift
//  SPENT
//
//  Created by Eric Nims on 1/27/22.
//

import Foundation
import GRDB

struct SplitTransaction: Identifiable, Codable, Hashable {
    var id: Int64?
    var transactionID: Int64
    var splitHeadTransactionID: Int64
    
    static let databaseUUIDEncodingStrategy = DatabaseUUIDEncodingStrategy.string
    var splitUUID: UUID
}

// SQL Database support
extension SplitTransaction: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "SplitTransactions"
    
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
    
    // Define database columns from CodingKeys
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let transactionID = Column(CodingKeys.transactionID)
        static let splitHeadTransactionID = Column(CodingKeys.splitHeadTransactionID)
        static let splitUUID = Column(CodingKeys.splitUUID)
    }
}

extension SplitTransaction {
    static let transaction = belongsTo(Transaction.self, using: ForeignKey(["transactionID"]))
    var transaction: QueryInterfaceRequest<Transaction> {
        request(for: SplitTransaction.transaction)
    }
    
    static let headTransaction = belongsTo(Transaction.self, using: ForeignKey(["splitHeadTransactionID"]))
    var headTransaction: QueryInterfaceRequest<Transaction> {
        request(for: SplitTransaction.headTransaction)
    }
    
    var members: QueryInterfaceRequest<SplitTransaction> {
        SplitTransaction.all().filter(splitUUID: self.splitUUID).filter(Columns.transactionID != Columns.splitHeadTransactionID)
    }
}

extension DerivableRequest where RowDecoder == SplitTransaction {
    func filter(splitUUID: UUID) -> Self {
        filter(SplitTransaction.Columns.splitUUID == splitUUID.uuidString)
    }
}
