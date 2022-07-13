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
    var selection: [Transaction] = []
    var allowedTypes: [UTType] = [.commaSeparatedText]
    var displayName: String = "CSV"
    let TAG_SEPARATOR: Character = ";"
    //let NULL_MARKER: String = "NULL"
    
    
    
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
                    if !bucketName.isEmpty {
                        let bucket = Bucket(id: nil, name: bucketName, category: "")
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
                                              status: mapStatusName(record.status),
                                              amount: NSDecimalNumber(string: record.amount).multiplying(by: 100).intValue,
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
    
    private func getFullSelection(database: Database) throws -> [Transaction] {
        // The csv contains all the transations in the db. All foreign key vales are resolved and converted to a string representaion.
        //TODO: Implement transaction batch processiong to reduce memory requirements
        // For now we fetch all the transactions in the db at once.
        let transactions = try Transaction.fetchAll(database, sql: """
            WITH "excludeList" ("id") AS (
                SELECT TransactionID FROM SplitTransactions
            )
            SELECT * FROM Transactions WHERE id NOT IN (SELECT * FROM excludeList)
        """)
        return transactions
    }

    func exportToURL(url: URL, database: DatabaseQueue) throws {
        try database.read { db in
            let stream = OutputStream(toFileAtPath: url.path, append: false)!
            let csv = try CSVWriter(stream: stream)
            // This is CSV schema v1
            // We exclude all "allocation" transactions from the export for compatibility since they only apply to this program
            // We also represent transfers as two transactions
            try csv.write(row: ["status", "amount", "date", "postDate", "bucket", "account", "memo", "payee", "tags"])

            var transactions = selection
            if selection.isEmpty {
                transactions = try getFullSelection(database: db)
            }
            
            for transaction in transactions {
                do {
                    let bucket = try transaction.bucket.fetchOne(db)
                    let account = try transaction.account.fetchOne(db)
                    let tags = try transaction.tags.fetchAll(db)
                    let tagNames = tags.map({ tag in tag.name })
                    try csv.write(row: [transaction.status.getStringName(),
                                        NSDecimalNumber(value: transaction.amount).dividing(by: 100).stringValue,
                                        transaction.entryDate.transactionFormat,
                                        transaction.postDate?.transactionFormat ?? "",
                                        bucket?.name ?? "",
                                        account?.name ?? "",
                                        transaction.memo,
                                        transaction.payee,
                                        tagNames.joined(separator: "\(TAG_SEPARATOR)")
                    ])
                } catch {
                    print("Failed to write transaction \(transaction.id ?? -1)")
                    print(error)
                }
            }
            csv.stream.close()
        }
    }
    
    func mapStatusName(_ statusName: String) -> Transaction.StatusTypes {
        // Update the status names
        if statusName == "Complete" {
            return .Complete // The string name of this is Cleared. It was changed from "Complete"
        }
        
        return Transaction.StatusTypes.fromString(string: statusName) ?? .Void
    }
    
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
    let amount: String
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
