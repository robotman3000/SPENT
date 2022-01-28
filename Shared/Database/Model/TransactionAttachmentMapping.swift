//
//  TransactionRecipts.swift
//  SPENT
//
//  Created by Eric Nims on 6/17/21.
//

import Foundation
import GRDB

struct TransactionAttachmentMapping: Identifiable, Codable, Hashable {
    var id: Int64?
    var transactionID: Int64
    var attachmentID: Int64
}

extension TransactionAttachmentMapping {
    static let transaction = belongsTo(Transaction.self, key: "TransactionID")
    var transaction: QueryInterfaceRequest<Transaction> {
        guard id != nil else {
            return Transaction.none()
        }
        return Transaction.filter(id: transactionID)
    }
    
    static let attachment = belongsTo(Attachment.self, key: "AttachmentID")
    var attachment: QueryInterfaceRequest<Attachment> {
        guard id != nil else {
            return Attachment.none()
        }
        return Attachment.filter(id: attachmentID)
    }
}


// SQL Database support
extension TransactionAttachmentMapping: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "TransactionAttachmentMap"
    
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
    
    // Define database columns from CodingKeys
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let transactionID = Column(CodingKeys.transactionID)
        static let attachmentID = Column(CodingKeys.attachmentID)
    }
}
