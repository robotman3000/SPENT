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
}

// Transactions
extension DatabaseStore {
    func updateTransaction(_ data: inout Transaction, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        print(data)
        do {
            try database!.saveTransaction(&data)
            onComplete()
        } catch {
            onError(error)
        }
    }

    func updateTransactions(_ data: inout [Transaction], onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        print(data)
        do {
            try database!.saveTransactions(&data)
            onComplete()
        } catch {
            onError(error)
        }
    }
    
    func deleteTransaction(_ id: Int64, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        deleteTransactions([id], onComplete: onComplete, onError: onError)
    }

    func deleteTransactions(_ ids: [Int64], onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        do {
            try database!.deleteTransactions(ids: ids)
            onComplete()
        } catch {
            onError(error)
        }
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
    
    func setTransactionTags(transaction: Transaction, tags: [Tag], onComplete: () -> Void = {}, onError: (Error) -> Void = printError) {
        do {
            try database!.setTransactionTags(transaction: transaction, tags: tags)
            onComplete()
        } catch {
            onError(error)
        }
    }
    
    func setTransactionsTags(transactions: [Transaction], tags: [Tag], onComplete: () -> Void = {}, onError: (Error) -> Void = printError) {
        do {
            try database!.setTransactionsTags(transactions: transactions, tags: tags)
            onComplete()
        } catch {
            onError(error)
        }
    }
}

// Buckets
extension DatabaseStore {
    func updateBucket(_ data: inout Bucket, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        print(data)
        do {
            try database!.saveBucket(&data)
            onComplete()
        } catch {
            onError(error)
        }
    }

    func deleteBucket(_ id: Int64, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        do {
            try database!.deleteBucket(id: id)
            onComplete()
        } catch {
            onError(error)
        }
    }
    
//    func getBucketByID(_ id: Int64?) -> Bucket? {
//        if id != nil, let ind = bucketIDMap[id!] {
//            return buckets.getByIndex(ind)
//        }
//        return nil
//    }
    
    static func getBucketTree(treeList: [Bucket]) -> [BucketNode] {
        print("Calculating bucket tree")
        //TODO: This must be made faster
        var nodes: [BucketNode] = []
        var idMap: [Int64: Int] = [:]
        var accounts: Set<BucketNode> = []
        var parentIDList: Set<Int64> = []
        var idList: Set<Int64> = []
        
        for i in 0..<treeList.count {
            let node = BucketNode(index: i, bucket: treeList[i])
            nodes.insert(node, at: i)
            if node.bucket.parentID != nil {
                parentIDList.insert(node.bucket.parentID!)
            }
            idList.insert(node.bucket.id!)
            idMap[node.bucket.id!] = node.index
        }
        
        //self.bucketIDMap = idMap
        
        // Now idList contains only the nodes with no children
        idList.subtract(parentIDList)
        //print(idList)
        while !idList.isEmpty {
            var newList: Set<Int64> = []
            for id in idList.sorted() {
                // Get the node
                let node = nodes[idMap[id]!]
                
                // If the node is not the top of the tree
                if node.bucket.parentID != nil {
                    // Get the parent node
                    let parent = nodes[idMap[node.bucket.parentID!]!]
                    
                    if parent.children == nil {
                        parent.children = []
                    }
                    // Add the child
                    parent.children?.append(node)
                    
                    // Store the parent for the next pass
                    newList.insert(parent.bucket.id!)
                } else {
                    // Store the top level node
                    accounts.insert(node)
                }
            }
            
            // Take a step up the tree and repeat
            idList = newList
        }
        
        return Array(accounts).sorted(by: { a, b in
            a.bucket.name < b.bucket.name
        })
    }
   
}

// Tags
extension DatabaseStore {
    func updateTag(_ data: inout Tag, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        print(data)
        do {
            try database!.saveTag(&data)
            onComplete()
        } catch {
            onError(error)
        }
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
    func updateTemplate(_ data: inout DBTransactionTemplate, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        print(data)
        do {
            try database!.saveTemplate(&data)
            onComplete()
        } catch {
            onError(error)
        }
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
