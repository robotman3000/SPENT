//
//  UIDatabaseConnector.swift
//  SPENT
//
//  Created by Eric Nims on 6/19/21.
//

import Foundation
import SwiftUI
import GRDB
import Combine

private func printError(error: Error) {
    print(error)
}

class DatabaseStore: ObservableObject {
    @Published var database: AppDatabase?
    
    func load(_ db: AppDatabase){
        if self.database != nil {
            self.database?.endSecureScope()
        }
        self.database = db
    }
    
    func getReader() -> DatabaseReader {
        return database!.databaseReader
    }
    
    func write(_ query: (_ db: Database) throws -> Void) throws {
        try database!.transaction(query)
    }
}

// Safe access api
extension DatabaseStore {
    /// Saves (inserts or updates) a transaction. When the method returns, the
    /// transaction is present in the database, and its id is not nil.
    func saveTransaction(_ db: Database, _ transaction: inout Transaction) throws {
//        if player.name.isEmpty {
//            throw ValidationError.missingName
//        }
        try transaction.save(db)
    }
    
    func saveTransactions(_ db: Database, _ transactions: inout [Transaction]) throws {
        for var t in transactions {
            try saveTransaction(db, &t)
        }
    }
    
    /// Delete the specified transactions
    func deleteTransactions(_ db: Database, ids: [Int64]) throws {
        // TODO: If transaction is a member of a group remove all other members
        // TODO: If transaction has tags assigned remove the tag assignments
        // TODO: If transaction has attachemtns remove the attachment assignments and the attachments
        
        // Get the id's of any group members not included in the set of id's
        let idStr = ids.map({ "\($0)" }).joined(separator: ", ")
        let extraIds = try Transaction.selectID().filter(sql: "\"Group\" IN (SELECT \"Group\" FROM Transactions WHERE id IN (\(idStr)))").fetchAll(db)
        _ = try Transaction.deleteAll(db, keys: ids + extraIds)
    }
    
    func saveTag(_ db: Database, _ tag: inout Tag) throws {
        try tag.save(db)
    }
    
    func deleteTag(_ db: Database, id: Int64) throws {
        // TODO: If tag is assigned to transactions remove the tag assignments
        _ = try Tag.deleteOne(db, id: id)
    }
    
    func setTransactionTags(_ db: Database, transaction: Transaction, tags: [Tag]) throws {
        try TransactionTag.filter(TransactionTag.Columns.transactionID == transaction.id!).deleteAll(db)
        try tags.forEach({ tag in
            var tTag = TransactionTag(id: nil, transactionID: transaction.id!, tagID: tag.id!)
            try tTag.save(db)
        })
    }
    
    func setTransactionsTags(_ db: Database, transactions: [Transaction], tags: [Tag]) throws {
        //TODO: This can be made faster
        for transaction in transactions {
            try TransactionTag.filter(TransactionTag.Columns.transactionID == transaction.id!).deleteAll(db)
            try tags.forEach({ tag in
                var tTag = TransactionTag(id: nil, transactionID: transaction.id!, tagID: tag.id!)
                try tTag.save(db)
            })
        }
    }
    
    func saveBucket(_ db: Database, _ bucket: inout Bucket) throws {
        try bucket.save(db)
    }
    
    func deleteBucket(_ db: Database, id: Int64) throws {
        //TODO: if bucket has transactions delete its transactions
        // TODO: if bucket has children delete the child buckets
        _ = try Bucket.deleteOne(db, id: id)
    }
    
    func deleteBuckets(_ db: Database, ids: [Int64]) throws {
        _ = try Bucket.deleteAll(db, ids: ids)
    }
    
    func saveTemplate(_ db: Database, _ template: inout DBTransactionTemplate) throws {
        try template.save(db)
    }
    
    func deleteTemplate(_ db: Database, id: Int64) throws {
        _ = try DBTransactionTemplate.deleteOne(db, id: id)
    }
    
    func saveAttachment(_ db: Database, _ attachment: inout Attachment) throws {
        try attachment.save(db)
    }
    
    func deleteAttachment(_ db: Database, id: Int64) throws {
        _ = try Attachment.deleteOne(db, id: id)
    }
    
    func addTransactionAttachment(_ db: Database, transaction: Transaction, attachment: Attachment) throws {
        var tAttachment = TransactionAttachment(id: nil, transactionID: transaction.id!, attachmentID: attachment.id!)
        try tAttachment.save(db)
    }
    
    //    func storeAttachment(sourceURL: URL, hash256: String) throws {
    //        var attachmentURL = database!.bundlePath!
    //        attachmentURL.appendPathComponent("attachments", isDirectory: true)
    //        attachmentURL.appendPathComponent(hash256.trunc(length: 2, trailing: ""), isDirectory: true)
    //        try FileManager.default.createDirectory(at: attachmentURL, withIntermediateDirectories: true, attributes: nil)
    //        attachmentURL.appendPathComponent(hash256)
    //        try FileManager.default.copyItem(at: sourceURL, to: attachmentURL)
    //    }
    //
    //    func exportAttachment(destinationURL: URL, attachment: Attachment) throws {
    //        var attachmentURL = database!.bundlePath!
    //        attachmentURL.appendPathComponent("attachments", isDirectory: true)
    //        attachmentURL.appendPathComponent(attachment.sha256.trunc(length: 2, trailing: ""), isDirectory: true)
    //        attachmentURL.appendPathComponent(attachment.sha256)
    //        var destURL = destinationURL
    //        destURL.appendPathComponent(attachment.filename)
    //        try FileManager.default.copyItem(at: attachmentURL, to: destURL)
    //    }
}
