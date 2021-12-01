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
}

// Transactions
extension DatabaseStore {
    func updateTransaction(_ data: inout Transaction, onComplete: () -> Void = {}) throws {
        try database!.saveTransaction(&data)
        onComplete()
    }

    func updateTransactions(_ data: inout [Transaction], onComplete: () -> Void = {}) throws {
        try database!.saveTransactions(&data)
        onComplete()
    }
    
    func deleteTransaction(_ id: Int64, onComplete: () -> Void = {}) throws {
        try deleteTransactions([id], onComplete: onComplete)
    }

    func deleteTransactions(_ ids: [Int64], onComplete: () -> Void = {}) throws {
        try database!.deleteTransactions(ids: ids)
        onComplete()
    }
    
    func getEmptyTransaction() -> Binding<Transaction> {
        return Binding<Transaction>(
            get: {
                Transaction(id: nil, status: .Uninitiated, date: Date(), amount: 0, type: .Invalid)
            },
            set: { _ in
                print("Trans binding: ignoring set")
            }
        )
    }
    
    func setTransactionTags(transaction: Transaction, tags: [Tag], onComplete: () -> Void = {}) throws {
        try database!.setTransactionTags(transaction: transaction, tags: tags)
        onComplete()
    }
    
    func setTransactionsTags(transactions: [Transaction], tags: [Tag], onComplete: () -> Void = {}) throws {
        try database!.setTransactionsTags(transactions: transactions, tags: tags)
        onComplete()
    }
}

// Buckets
extension DatabaseStore {
    func updateBucket(_ data: inout Bucket, onComplete: () -> Void = {}) throws {
        try database!.saveBucket(&data)
        onComplete()
    }

    func deleteBucket(_ id: Int64, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        do {
            try database!.deleteBucket(id: id)
            onComplete()
        } catch {
            onError(error)
        }
    }
}

// Tags
extension DatabaseStore {
    func updateTag(_ data: inout Tag, onComplete: () -> Void = {}) throws {
        try database!.saveTag(&data)
        onComplete()
    }

    func deleteTag(_ id: Int64, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        do {
            try database!.deleteTag(id: id)
            onComplete()
        } catch {
            onError(error)
        }
    }
}

// Schedules
extension DatabaseStore {
    func updateSchedule(_ data: inout Schedule, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        print(data)
        do {
            try database!.saveSchedule(&data)
            onComplete()
        } catch {
            onError(error)
        }
    }

    func deleteSchedule(_ id: Int64, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        do {
            try database!.deleteSchedule(id: id)
            onComplete()
        } catch {
            onError(error)
        }
    }
}

// Transaction Templates
extension DatabaseStore {
    func updateTemplate(_ data: inout DBTransactionTemplate, onComplete: () -> Void = {}) throws {
        try database!.saveTemplate(&data)
        onComplete()
    }

    func deleteTemplate(_ id: Int64, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        do {
            try database!.deleteTemplate(id: id)
            onComplete()
        } catch {
            onError(error)
        }
    }
}

// Attachments
extension DatabaseStore {
    func updateAttachmentRecord(_ data: inout Attachment, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        print(data)
        do {
            try database!.saveAttachment(&data)
            onComplete()
        } catch {
            onError(error)
        }
    }

    func deleteAttachment(_ id: Int64, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        do {
            try database!.deleteAttachment(id: id)
            onComplete()
        } catch {
            onError(error)
        }
    }
    
    func addTransactionAttachment(transaction: Transaction, attachment: Attachment, onComplete: () -> Void = {}, onError: (Error) -> Void = printError) {
        do {
            try database!.addTransactionAttachment(transaction: transaction, attachment: attachment)
            onComplete()
        } catch {
            onError(error)
        }
    }

    func storeAttachment(sourceURL: URL, hash256: String) throws {
        var attachmentURL = database!.bundlePath!
        attachmentURL.appendPathComponent("attachments", isDirectory: true)
        attachmentURL.appendPathComponent(hash256.trunc(length: 2, trailing: ""), isDirectory: true)
        try FileManager.default.createDirectory(at: attachmentURL, withIntermediateDirectories: true, attributes: nil)
        attachmentURL.appendPathComponent(hash256)
        try FileManager.default.copyItem(at: sourceURL, to: attachmentURL)
    }

    func exportAttachment(destinationURL: URL, attachment: Attachment) throws {
        var attachmentURL = database!.bundlePath!
        attachmentURL.appendPathComponent("attachments", isDirectory: true)
        attachmentURL.appendPathComponent(attachment.sha256.trunc(length: 2, trailing: ""), isDirectory: true)
        attachmentURL.appendPathComponent(attachment.sha256)
        var destURL = destinationURL
        destURL.appendPathComponent(attachment.filename)
        try FileManager.default.copyItem(at: attachmentURL, to: destURL)
    }
    
    func getAllAttachments() -> [Attachment] {
        return database?.resolve(Attachment.all()) ?? []
    }
}
