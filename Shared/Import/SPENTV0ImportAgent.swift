//
//  SPENTV0ImportAgent.swift
//  SPENT
//
//  Created by Eric Nims on 9/11/21.
//

import Foundation
import GRDB
import UniformTypeIdentifiers

struct SPENTV0ImportAgent: ImportAgent {
    let allowedTypes: [UTType] = []
    func importFromURL(url: URL, database: DatabaseStore) throws {
        let newURL = url.appendingPathComponent("db.sqlite")
        if url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }
            // Then connect to it
            print("Connecting to database file")
            let dbQueue = try DatabaseQueue(path: newURL.path)
            
            // And proceed to read everything into memory
            
            /* Note: We are able to create the new database objects using the old data
             because the old and new still bear a close resemblance. This is subject to change
             */
            var buckets: [Bucket] = []
            var tags: [Tag] = []
            var transactions: [Transaction] = []
            var transactionTags: [TransactionTag] = []
            
            try dbQueue.read { db in
                // Start with the buckets/accounts
                print("Reading buckets...")
                let bucketRows = try Row.fetchCursor(db, sql: "SELECT * FROM Buckets")
                while let row = try bucketRows.next() {
                    let id: Int64 = row["id"]
                    let name: String = row["Name"]
                    var parent: Int64? = row["Parent"]
                    var ancestor: Int64? = row["Ancestor"]
                    let memo: String = row["Memo"]
                    
                    // Skip the "ROOT" account
                    if id == -1 {
                        continue
                    }
                    
                    // Remove/fix all references to the ROOT account
                    if parent == -1 || parent == nil {
                        parent = nil
                    }
                    if ancestor == -1 || ancestor == nil {
                        ancestor = nil
                    }
                    
                    // Create the new db object
                    buckets.append(Bucket(id: id, name: name, parentID: parent, ancestorID: ancestor, memo: memo))
                }
                
                // Then fetch the tags
                print("Reading tags...")
                let tagRows = try Row.fetchCursor(db, sql: "SELECT * FROM Tags")
                while let row = try tagRows.next() {
                    let id: Int64 = row["id"]
                    let name: String = row["Name"]
                    let memo: String = row["Memo"]
                
                    // Create the new db object
                    tags.append(Tag(id: id, name: name, memo: memo))
                }
                
                // Followed by the transactions
                let statusMap: [Int : Transaction.StatusTypes] = [0: .Void, 1: .Uninitiated, 3: .Submitted, 4: .Posting, 5: .Complete, 6: .Reconciled]
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
                dateFormatter.dateFormat = "yyyy-MM-dd"
                print("Reading transactions...")
                let transactionRows = try Row.fetchCursor(db, sql: "SELECT * FROM Transactions")
                while let row = try transactionRows.next() {
                    let id: Int64 = row["id"]
                    let status: Int = row["Status"]
                    let date: Date = row["TransDate"]
                    let postDate: Date? = row["PostDate"]
                    let amount: Int = row["Amount"]
                    var source: Int64? = row["SourceBucket"]
                    var destination: Int64? = row["DestBucket"]
                    let memo: String = row["Memo"]
                    let payee: String? = row["Payee"]
                    let group: String? = row["Group"]
                    
                    // Update the status value
                    let newStatus = statusMap[status] ?? .Void
                    
                    //let newDate = dateFormatter.date(from:date)!
                    //let newPDate = dateFormatter.date(from:postDate ?? "")
                    
                    // Remove/fix all references to the ROOT account
                    if source == -1 || source == nil {
                        source = nil
                    }
                    if destination == -1 || destination == nil {
                        destination = nil
                    }
                    
                    let sDate: Date? = source != nil ? postDate : nil
                    let dDate: Date? = destination != nil ? postDate : nil
                    
                    // Create the new db object
                    transactions.append(Transaction(id: id, status: newStatus, date: date, sourcePosted: sDate, destPosted: dDate, amount: amount, sourceID: source, destID: destination, memo: memo, payee: payee, group: UUID(uuidString: group ?? ""), type: .Invalid))
                }
                
                
                // And finally the tag assignments (TransactionTags)
                print("Reading tag assignments...")
                let tTagRows = try Row.fetchCursor(db, sql: "SELECT * FROM TransactionTags")
                while let row = try tTagRows.next() {
                    let id: Int64 = row["id"]
                    let tag: Int64 = row["TagID"]
                    let transaction: Int64 = row["TransactionID"]
                    
                    // Create the new db object
                    transactionTags.append(TransactionTag(id: id, transactionID: transaction, tagID: tag))
                }
            }
            
            print("Preparing to commit imported data")
            try database.write { db in
                // Having created all the database objects, we now proceed to store them
                // We turn off foreign key verification so that we don't have any "doesn't exist when needed" issues
                
                print("Commiting buckets...")
                for var bucket in buckets {
                    try bucket.save(db)
                }
                
                print("Commiting tags...")
                for var tag in tags {
                    try tag.save(db)
                }
                
                print("Commiting transactions...")
                for var transaction in transactions {
                    try transaction.save(db)
                }
                
                print("Commiting tag assignments...")
                for var tTag in transactionTags {
                    try tTag.save(db)
                }
            }
            
            print("Import complete")
        } else {
            print("Failed to open file")
        }
    }
}
