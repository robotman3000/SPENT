//
//  CSVExportAgent.swift
//  iOS
//
//  Created by Eric Nims on 1/25/22.
//

import Foundation
import CSV
import UniformTypeIdentifiers
import GRDB

struct CSVAgent : ImportAgent, ExportAgent {
    var allowedTypes: [UTType] = [.commaSeparatedText]
    var displayName: String = "CSV"
    let TAG_SEPARATOR: Character = ";"
    let NULL_MARKER: String = "NULL"
    
    func importFromURL(url: URL, database: DatabaseQueue) throws {
        
        var records = [CSVTransactionRow_V1]()
        do {
            let stream = InputStream(fileAtPath: url.path)!
            let reader = try CSVReader(stream: stream, hasHeaderRow: true)
            let decoder = CSVRowDecoder()
            while reader.next() != nil {
                let row = try decoder.decode(CSVTransactionRow_V1.self, from: reader)
                records.append(row)
            }
        } catch {
            print(error)
            // Invalid row format
        }

        // TODO: Don't assume the database is empty
        try database.write({ db in
            // Create all the accounts
            var accounts: Set<Account> = Set()
            var buckets: Set<Bucket> = Set()
            var tags: Set<Tag> = Set()
            for record in records {
                // Initialize the account
                let account = Account(id: nil, name: record.account)
                accounts.insert(account)
                
                // Create the bucket (if present)
                if let bucketName = record.bucket {
                    if bucketName != NULL_MARKER {
                        let bucket = Bucket(id: nil, name: bucketName)
                        buckets.insert(bucket)
                    }
                }
                
                // Create the tags (if present)
                if record.tags != nil && !record.tags!.isEmpty {
                    let tagStrings = record.tags!.split(separator: TAG_SEPARATOR)
                    tagStrings.forEach({ tag in tags.insert(Tag(id: nil, name: String(tag))) })
                }
            }
            
            for var i in accounts {
                try i.save(db)
            }

            for var i in buckets {
                try i.save(db)
            }
            
            for var i in tags {
                try i.save(db)
            }
            
            for record in records {
                let account = try Account.filter(Account.Columns.name == record.account).fetchOne(db)
                let bucket = try Bucket.filter(Bucket.Columns.name == record.bucket).fetchOne(db)
                let entryDate = stringToDate(dateString: record.date)
                let postDate = stringToDate(dateString: record.postDate ?? "")
                
                guard account != nil && entryDate != nil else {
                    throw RuntimeError("Invalid CSV file")
                }
                
                var transaction = Transaction(id: nil,
                                              status: Transaction.StatusTypes.fromString(string: record.status) ?? .Void,
                                              amount: record.amount,
                                              payee: record.payee ?? "",
                                              memo: record.memo,
                                              entryDate: entryDate!,
                                              postDate: postDate,
                                              bucketID: bucket?.id,
                                              accountID: account!.id!)
                try transaction.save(db)
                
                // TODO: Assign the tags to the transaction
            }
        })
    }
    
    func exportToURL(url: URL, database: DatabaseQueue) throws {
//        try database.read { db in
//            let stream = OutputStream(toFileAtPath: url.path, append: false)!
//            let csv = try CSVWriter(stream: stream)
//
//            // The csv contains all the transations in the db. All foreign key vales are resolved and converted to a string representaion.
//
//            //TODO: Implement transaction batch processiong to reduce memory requirements
//            // For now we fetch all the transactions in the db at once.
//            let transactions = try Transaction.all().orderByPrimaryKey().fetchAll(db)
//
//            // This is CSV schema v1
//            // We exclude all "allocation" transactions from the export for compatibility
//            // We also represent transfers as two transactions
//            try csv.write(row: ["status", "amount", "date", "postDate", "bucket", "account", "memo", "payee", "tags"])
//
//            for transaction in transactions {
//                do {
//                    if transaction.group == nil { // Exclude split transactions
//                        let sourceBucket = try transaction.source.fetchOne(db)
//                        let sourceAccount = try sourceBucket?.ancestor.fetchOne(db)
//                        let destinationBucket = try transaction.destination.fetchOne(db)
//                        let destinationAccount = try destinationBucket?.ancestor.fetchOne(db)
//
//                        let tags = try transaction.tags.fetchAll(db)
//                        let tagNames = tags.map({ tag in tag.name })
//
//                        // If the transaction/transfer is between two seperate trees
//                        if isRealTransaction(source: sourceBucket, destination: destinationBucket) {
//                            // These initial values are valid for a transfer and for a deposit
//                            var bucket: String = (destinationAccount != nil ? destinationBucket?.name ?? NULL_MARKER : NULL_MARKER)
//                            var account: String = destinationAccount?.name ?? destinationBucket?.name ?? NULL_MARKER
//                            var amount = transaction.amount
//                            var postDate: Date? = transaction.destPosted
//
//                            if transaction.type == .Withdrawal {
//                                bucket = (sourceAccount != nil ? sourceBucket?.name ?? NULL_MARKER : NULL_MARKER)
//                                account = sourceAccount?.name ?? sourceBucket?.name ?? NULL_MARKER
//                                amount = transaction.amount * -1
//                                postDate = transaction.sourcePosted
//                            }
//
//                            // In the case of a transfer write the source before the destination
//                            if transaction.type == .Transfer {
//                                try csv.write(row: [transaction.status.getStringName(),
//                                                    "\(-1*amount)",
//                                                    transaction.date.transactionFormat,
//                                                    transaction.sourcePosted?.transactionFormat ?? NULL_MARKER,
//                                                    (sourceAccount != nil ? sourceBucket?.name ?? NULL_MARKER : NULL_MARKER),
//                                                    sourceAccount?.name ?? sourceBucket?.name ?? NULL_MARKER,
//                                                    transaction.memo,
//                                                    transaction.payee ?? "",
//                                                    tagNames.joined(separator: TAG_SEPARATOR)
//                                ])
//                            }
//
//                            try csv.write(row: [transaction.status.getStringName(),
//                                                "\(amount)",
//                                                transaction.date.transactionFormat,
//                                                postDate?.transactionFormat ?? NULL_MARKER,
//                                                bucket,
//                                                account,
//                                                transaction.memo,
//                                                transaction.payee ?? "",
//                                                tagNames.joined(separator: TAG_SEPARATOR)
//                            ])
//                        } else {
//                            print("Skipping allocation transaction \(transaction.id ?? -1)")
//                        }
//                    } else {
//                        print("Skipping split transaction \(transaction.id ?? -1)")
//                    }
//                } catch {
//                    print("Failed to write transaction \(transaction.id ?? -1)")
//                    print(error)
//                }
//            }
//            csv.stream.close()
//        }
    }
    
//    private func isRealTransaction(source: Bucket?, destination: Bucket?) -> Bool {
//        // First get the account id for the source and destination buckets
//        let sourceID: Int64 = source?.ancestorID ?? source?.id! ?? -1
//        let destinationID: Int64 = destination?.ancestorID ?? destination?.id! ?? -1
//        return sourceID != destinationID
//    }
    
    func stringToDate(dateString: String) -> Date? {
        // Create Date Formatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, y"

        // Convert Date to String
        return dateFormatter.date(from: dateString)
    }
}

private struct CSVTransactionRow_V1: Decodable {
    let status: String
    let amount: Int
    let date: String
    let postDate: String?
    let bucket: String?
    let account: String
    let memo: String
    let payee: String?
    let tags: String?
}

private struct RuntimeError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    public var localizedDescription: String {
        return message
    }
    
    public var errorDescription: String? {
        return message
    }
}
