//
//  LegacyImportAgent.swift
//  macOS
//
//  Created by Eric Nims on 8/24/21.
//

import Foundation
import GRDB

class SPENTLegacyImportAgent: ImportAgent {
    func importFromURL() {
    }
    
    static func importSPENTLegacy(url: URL, dbStore: DatabaseStore) throws {
        //TODO: This function will eventually need to be split up and moved into the import and export manager (Once ready)
        
        if url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }
            
            // Then connect to it
            let dbQueue = try DatabaseQueue(path: url.path)
            
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
                let bucketRows = try Row.fetchCursor(db, sql: "SELECT * FROM Buckets")
                while let row = try bucketRows.next() {
                    let id: Int64 = row["id"]
                    let name: String = row["Name"]
                    var parent: Int64? = row["Parent"]
                    var ancestor: Int64? = row["Ancestor"]
                    
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
                    buckets.append(Bucket(id: id, name: name, parentID: parent, ancestorID: ancestor))
                }
                
                // Then fetch the tags
                let tagRows = try Row.fetchCursor(db, sql: "SELECT * FROM Tags")
                while let row = try tagRows.next() {
                    let id: Int64 = row["id"]
                    let name: String = row["Name"]
                
                    // Create the new db object
                    tags.append(Tag(id: id, name: name, memo: ""))
                }
                
                // Followed by the transactions
                let statusMap: [Int : Transaction.StatusTypes] = [0: .Void, 1: .Uninitiated, 2: .Submitted, 3: .Posting, 4: .Complete, 5: .Reconciled]
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let transactionRows = try Row.fetchCursor(db, sql: "SELECT * FROM Transactions")
                while let row = try transactionRows.next() {
                    let id: Int64 = row["id"]
                    let status: Int = row["Status"]
                    let date: String = row["TransDate"]
                    let postDate: String? = row["PostDate"]
                    let amount: String = row["Amount"]
                    var source: Int64? = row["SourceBucket"]
                    var destination: Int64? = row["DestBucket"]
                    let memo: String = row["Memo"] ?? ""
                    let payee: String? = row["Payee"]
                
                    // Update the status value
                    let newStatus = statusMap[status] ?? .Void
                    
                    // Convert the amount from a floating point to an int
                    let newAmount = Int(round(Double(amount)! * 100))
                    
                    let newDate = dateFormatter.date(from:date)!
                    let newPDate = dateFormatter.date(from:postDate ?? "")
                    
                    // Remove/fix all references to the ROOT account
                    if source == -1 || source == nil {
                        source = nil
                    }
                    if destination == -1 || destination == nil {
                        destination = nil
                    }
                    
                    let sDate: Date? = source != nil ? newPDate : nil
                    let dDate: Date? = destination != nil ? newPDate : nil
                    
                    
                    // Create the new db object
                    transactions.append(Transaction(id: id, status: newStatus, date: newDate, sourcePosted: sDate, destPosted: dDate, amount: newAmount, sourceID: source, destID: destination, memo: memo, payee: payee, group: nil, type: .Invalid))
                }
                
                
                // And finally the tag assignments (TransactionTags)
                let tTagRows = try Row.fetchCursor(db, sql: "SELECT * FROM TransactionTags")
                while let row = try tTagRows.next() {
                    let id: Int64 = row["id"]
                    let tag: Int64 = row["TagID"]
                    let transaction: Int64 = row["TransactionID"]
                    
                    // Create the new db object
                    transactionTags.append(TransactionTag(id: id, transactionID: transaction, tagID: tag))
                }
            }
            
            try dbStore.database!.getWriter().write { db in
                // Having created all the database objects, we now proceed to store them
                // We turn off foreign key verification so that we don't have any "doesn't exist when needed" issues
                
                for var bucket in buckets {
                    try bucket.save(db)
                }
                
                for var tag in tags {
                    try tag.save(db)
                }
                
                for var transaction in transactions {
                    try transaction.save(db)
                }
                
                for var tTag in transactionTags {
                    try tTag.save(db)
                }
            }
        }
    }
}
