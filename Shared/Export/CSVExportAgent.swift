//
//  CSVExportAgent.swift
//  iOS
//
//  Created by Eric Nims on 1/25/22.
//

import Foundation
import CSV

struct CSVExportAgent : ExportAgent {
    let TAG_SEPARATOR: String = ";"
    let NULL_MARKER: String = "NULL"
    
    func exportToURL(url: URL, database: DatabaseStore) throws {
        try database.getReader().read { db in
            let stream = OutputStream(toFileAtPath: url.path, append: false)!
            let csv = try CSVWriter(stream: stream)
            
            // The csv contains all the transations in the db. All foreign key vales are resolved and converted to a string representaion.
            
            //TODO: Implement transaction batch processiong to reduce memory requirements
            // For now we fetch all the transactions in the db at once.
            let transactions = try Transaction.all().orderByPrimaryKey().fetchAll(db)
            
            /*
             var status: StatusTypes
             var date: Date
             var sourcePosted: Date?
             var destPosted: Date?
             var amount: Int
             var sourceID: Int64?
             var destID: Int64?
             var memo: String = ""
             var payee: String?
             
             static let databaseUUIDEncodingStrategy = DatabaseUUIDEncodingStrategy.string
             var group: UUID?
             */
            
            
            // This is CSV schema v1
            // We exclude all "allocation" transactions from the export for compatibility
            // We also represent transfers as two transactions
            try csv.write(row: ["status", "amount", "date", "postDate", "bucket", "account", "memo", "payee", "tags"])
            
            for transaction in transactions {
                do {
                    if transaction.group == nil { // Exclude split transactions
                        let sourceBucket = try transaction.source.fetchOne(db)
                        let sourceAccount = try sourceBucket?.ancestor.fetchOne(db)
                        let destinationBucket = try transaction.destination.fetchOne(db)
                        let destinationAccount = try destinationBucket?.ancestor.fetchOne(db)
                        
                        let tags = try transaction.tags.fetchAll(db)
                        let tagNames = tags.map({ tag in tag.name })
                        
                        // If the transaction/transfer is between two seperate trees
                        if isRealTransaction(source: sourceBucket, destination: destinationBucket) {
                            // These initial values are valid for a transfer and for a deposit
                            var bucket = (destinationAccount != nil ? destinationBucket?.name ?? NULL_MARKER : NULL_MARKER)
                            var account = destinationAccount?.name ?? destinationBucket?.name ?? NULL_MARKER
                            var amount = transaction.amount
                            var postDate: Date? = transaction.destPosted
                            
                            if transaction.type == .Withdrawal {
                                bucket = (sourceAccount != nil ? sourceBucket?.name ?? NULL_MARKER : NULL_MARKER)
                                account = sourceAccount?.name ?? sourceBucket?.name ?? NULL_MARKER
                                amount = transaction.amount * -1
                                postDate = transaction.sourcePosted
                            }
                            
                            // In the case of a transfer write the source before the destination
                            if transaction.type == .Transfer {
                                try csv.write(row: [transaction.status.getStringName(),
                                                    "\(-1*amount)",
                                                    transaction.date.transactionFormat,
                                                    transaction.sourcePosted?.transactionFormat ?? NULL_MARKER,
                                                    (sourceAccount != nil ? sourceBucket?.name ?? NULL_MARKER : NULL_MARKER),
                                                    sourceAccount?.name ?? sourceBucket?.name ?? NULL_MARKER,
                                                    transaction.memo,
                                                    transaction.payee ?? "",
                                                    tagNames.joined(separator: TAG_SEPARATOR)
                                ])
                            }
                            
                            try csv.write(row: [transaction.status.getStringName(),
                                                "\(amount)",
                                                transaction.date.transactionFormat,
                                                postDate?.transactionFormat ?? NULL_MARKER,
                                                bucket,
                                                account,
                                                transaction.memo,
                                                transaction.payee ?? "",
                                                tagNames.joined(separator: TAG_SEPARATOR)
                            ])
                        } else {
                            print("Skipping allocation transaction \(transaction.id ?? -1)")
                        }
                    } else {
                        print("Skipping split transaction \(transaction.id ?? -1)")
                    }
                } catch {
                    print("Failed to write transaction \(transaction.id ?? -1)")
                    print(error)
                }
            }
            csv.stream.close()
        }
    }
    
    func isRealTransaction(source: Bucket?, destination: Bucket?) -> Bool {
        // First get the account id for the source and destination buckets
        let sourceID: Int64 = source?.ancestorID ?? source?.id! ?? -1
        let destinationID: Int64 = destination?.ancestorID ?? destination?.id! ?? -1
        return sourceID != destinationID
    }
}
