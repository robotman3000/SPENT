//
//  TransactionRecipts.swift
//  SPENT
//
//  Created by Eric Nims on 6/17/21.
//

import Foundation
import GRDB

struct TransactionAttachment: Identifiable, Codable, Hashable {
    var id: Int64?
    var transactionID: Int64
    var attachmentID: Int64
    
    private enum CodingKeys: String, CodingKey {
        case id, transactionID = "TransactionID", attachmentID = "AttachmentID"
    }
}

extension TransactionAttachment {
    static let transaction = belongsTo(Transaction.self, key: "TransactionID")
    var transaction: QueryInterfaceRequest<Transaction> {
        guard id != nil else {
            return Transaction.none()
        }
        return Transaction.filter(id: transactionID)
    }
    
    static let recipt = belongsTo(Attachment.self, key: "AttachmentID")
    var recipt: QueryInterfaceRequest<Attachment> {
        guard id != nil else {
            return Attachment.none()
        }
        return Attachment.filter(id: attachmentID)
    }
}


// SQL Database support
extension TransactionAttachment: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "Attachments"
    
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
