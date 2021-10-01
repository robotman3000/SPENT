//
//  AppDatabase.swift
//  SPENT
//
//  Created by Eric Nims on 5/12/21.
//

import Combine
import GRDB
import Foundation
import SwiftUI

/// AppDatabase lets the application access the database.
///
/// It applies the pratices recommended at
/// https://github.com/groue/GRDB.swift/blob/master/Documentation/GoodPracticesForDesigningRecordTypes.md
struct AppDatabase {
    
    static var DB_VERSION: Int64 = 3
    var bundlePath: URL?
    
    func endSecureScope(){
        print("stopAccessingSecurityScopedResource")
        if let url = bundlePath {
            url.stopAccessingSecurityScopedResource()
            print("OK")
        } else {
            print("FAIL")
        }
    }
    
    init() throws {
        print("Using Memory DB")
        self.dbWriter = DatabaseQueue()
        try migrator.migrate(dbWriter)
    }
    
    init(path: URL, trace: Bool = true) throws {
        self.bundlePath = path
        let newURL = path.appendingPathComponent("db.sqlite")
        print("Using DB from path: \(newURL.path)")
        self.dbWriter = try DatabaseQueue(path: newURL.path)
        if trace {
            try databaseReader.read { db in
                db.trace(options: .statement) { event in
                    print("SQL: \(event)")
                }
            }
        }
        try migrator.migrate(dbWriter)
    }
    
    /// Provides access to the database.
    ///
    /// Application can use a `DatabasePool`, while SwiftUI previews and tests
    /// can use a fast in-memory `DatabaseQueue`.
    ///
    /// See https://github.com/groue/GRDB.swift/blob/master/README.md#database-connections
    private let dbWriter: DatabaseWriter
    
    /// The DatabaseMigrator that defines the database schema.
    ///
    /// See https://github.com/groue/GRDB.swift/blob/master/Documentation/Migrations.md
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        #if DEBUG
        // Speed up development by nuking the database when migrations change
        // See https://github.com/groue/GRDB.swift/blob/master/Documentation/Migrations.md#the-erasedatabaseonschemachange-option
        //migrator.eraseDatabaseOnSchemaChange = true
        #endif
        
        migrator.registerMigration("v1") { db in
            /// This is the initial version one schema
//            db.trace(options: .statement) { event in
//                print("SQL: \(event)")
//            }
//            
            // Create a table
            // See https://github.com/groue/GRDB.swift#create-tables
            try db.create(table: "Tags") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("Name", .text).notNull().unique()
                t.column("Memo", .text).notNull().defaults(to: "")
                t.column("Color", .text).notNull().defaults(to: "#8c8c8c")
                t.column("Favorite", .boolean).notNull().defaults(to: false)
            }
            
            // Create recipts table
            try db.create(table: "TransactionTemplates") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("Template", .text).notNull()
            }
            
            try db.create(table: "Schedules") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("Name", .text).notNull().unique()
                t.column("Template", .integer).references("TransactionTemplates")
                t.column("Memo", .text).notNull().defaults(to: "")
                t.column("Favorite", .boolean).notNull().defaults(to: false)
            }
            
            try db.create(table: "Buckets") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("Name", .text).notNull().unique()
                t.column("Parent", .integer).references("Buckets", onDelete: .cascade)
                t.column("Ancestor", .integer).references("Buckets", onDelete: .cascade)
                t.column("Memo", .text).notNull().defaults(to: "")
                t.column("Favorite", .boolean).notNull().defaults(to: false)
                t.column("V_Ancestor", .integer).generatedAs(sql: "IFNULL(Ancestor, id)")
            }
            
            try db.create(table: "Transactions") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("Status", .integer).notNull().check {
                    // This status is only used in code and shouldn't get stored
                    $0 != Transaction.StatusTypes.Scheduled
                }
                t.column("TransDate", .date).notNull()
                t.column("SourcePostDate", .date)//.check {
                //    $0 == nil || $0 >= transDate
                //}
                t.column("DestPostDate", .date)
                t.column("Amount", .integer).notNull().check {
                    // While things won't break with negative values, we don't allow them in the DB because it would start to get confusing to the end user
                    // I.E Negatives don't really make sense here
                    $0 >= 0
                }
                //TODO: Eventually this will have to set the source or dest to the ancestor account if a bucket is deleted
                // and delete the transaction if the ancestor account is being deleted
                t.column("SourceBucket", .integer).references("Buckets")//, onDelete: .cascade)
                t.column("DestBucket", .integer).references("Buckets")//, onDelete: .cascade)
                t.column("Memo", .text).notNull().defaults(to: "")
                t.column("Payee", .text)
                t.column("Group", .text) // String UUID
                
                // Order as written
                /*
                 Split Head
                 Split Member
                 Transfer
                 Withdrawal
                 Deposit
                 Unknown
                 */
                t.column("V_Type", .integer).generatedAs(sql: """
                   CASE
                       WHEN "SourceBucket" IS NULL AND "DestBucket" IS NULL AND "Group" IS NOT NULL THEN 5
                       WHEN "SourceBucket" IS NOT NULL AND "DestBucket" IS NOT NULL AND "Group" IS NOT NULL THEN 4
                       WHEN "SourceBucket" IS NOT NULL AND "DestBucket" IS NOT NULL AND "Group" IS NULL THEN 3
                       WHEN "SourceBucket" IS NOT NULL AND "DestBucket" IS NULL AND "Group" IS NULL THEN 2
                       WHEN "SourceBucket" IS NULL AND "DestBucket" IS NOT NULL AND "Group" IS NULL THEN 1
                       ELSE 0
                   END
                """)
                
                //t.column("V_Date", .integer).generatedAs(sql: "IFNULL(PostDate, TransDate)")
                
            }
            
            try db.create(table: "TransactionTags") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("TransactionID", .integer).notNull().references("Transactions", onDelete: .cascade)
                
                // It should not be possible to delete a tag assigned to a transaction by cascade because
                // the schedules table depends on the presence of tags it has assigned.
                // TODO: Use program logic to determine if a tag can be deleted
                t.column("TagID", .integer).notNull().references("Tags")
                t.uniqueKey(["TransactionID", "TagID"], onConflict: .replace)
            }
            
            // Create attachments table
            try db.create(table: "Attachments") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("Filename", .text).notNull()
                
                // The hash is for file security/integrity
                // The unique helps ensure that duplicate files can't be added
                t.column("SHA256", .text).notNull().unique()
            }
            
            // Create attachment assignments
            try db.create(table: "TransactionAttachments") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("TransactionID", .integer).notNull().references("Transactions", onDelete: .cascade)
                t.column("AttachmentID", .integer).notNull().references("Attachments", onDelete: .cascade)
            }
            
            // VIEW - Transaction Ancestors
            try db.execute(sql: """
                CREATE VIEW transactionAncestors AS
                SELECT t.id AS tid,
                       b1.V_Ancestor AS sa,
                       b2.V_Ancestor AS da
                FROM Transactions t
                LEFT JOIN Buckets b1 ON SourceBucket = b1.id
                LEFT JOIN Buckets b2 ON DestBucket = b2.id
                WHERE IFNULL(sa, -1) != IFNULL(da, -1)
            """)

            // VIEW - Transaction Amounts
            try db.execute(sql: """
                CREATE VIEW transactionAmounts AS
                SELECT id AS "tid",
                       -1*Amount AS amount,
                       SourceBucket AS bid,
                       Status
                FROM Transactions
                WHERE SourceBucket IN (SELECT id FROM Buckets)
                UNION ALL
                SELECT id AS "tid",
                       Amount AS amount,
                       DestBucket AS bid,
                       Status
                FROM Transactions
                WHERE DestBucket IN (SELECT id FROM Buckets)
            """)
            
            // VIEW - Bucket Balance
            try db.execute(sql: """
                CREATE VIEW bucketBalance AS
                SELECT DISTINCT
                        r.bid,
                        IFNULL(available, 0)+IFNULL(posted, 0) AS "available",
                        posted
                FROM transactionAmounts r
                LEFT JOIN (
                    SELECT SUM(amount) AS "available", bid
                    FROM transactionAmounts
                    WHERE Status IN (SELECT * FROM aStatus)
                    GROUP BY bid
                ) "a" ON r.bid == a.bid
                LEFT JOIN (
                    SELECT SUM(amount) AS "posted", bid
                    FROM transactionAmounts
                    WHERE Status IN (SELECT * FROM pStatus)
                    GROUP BY bid
                ) "p" ON r.bid == p.bid
            """)
        }

        migrator.registerMigration("DB-Versioning"){ db in
            try db.create(table: "appConfiguration") { t in
                // Single row guarantee
                t.column("id", .integer)
                    // Have inserts replace the existing row
                    .primaryKey(onConflict: .replace)
                    // Make sure the id column is always 1
                    .check { $0 == 1 }
                
                // The configuration colums
                
                // This column is used to protect the saved databases from being used with a
                // commit other than the one they were created with.
                // Remove this once the first non beta build is released and use
                // schema migrations instead.
                t.column("commitHash", .text).notNull()
                t.column("dbVersion", .integer).notNull()
            }
        }
        // Migrations for future application versions will be inserted here:
        // migrator.registerMigration(...) { db in
        //     ...
        // }
        
        return migrator
    }
}

// MARK: - Database Access: Writes

extension AppDatabase {
    /// A validation error that prevents some players from being saved into
    /// the database.
    enum ValidationError: LocalizedError {
        case missingName
        
        var errorDescription: String? {
            switch self {
            case .missingName:
                return "Please provide a name"
            }
        }
    }
    
    func getWriter() -> DatabaseWriter {
        return dbWriter
    }
    
    /// Saves (inserts or updates) a transaction. When the method returns, the
    /// transaction is present in the database, and its id is not nil.
    func saveTransaction(_ transaction: inout Transaction) throws {
//        if player.name.isEmpty {
//            throw ValidationError.missingName
//        }
        try dbWriter.write { db in
            try transaction.save(db)
        }
    }
    
    func saveTransactions(_ transactions: inout [Transaction]) throws {
//        if player.name.isEmpty {
//            throw ValidationError.missingName
//        }
        try dbWriter.write { db in
            for var t in transactions {
                try t.save(db)
            }
        }
    }
    
    /// Delete the specified transactions
    func deleteTransactions(ids: [Int64]) throws {
        try dbWriter.write { db in
            _ = try Transaction.deleteAll(db, keys: ids)
        }
    }
    
    /// Delete all transactions
    func deleteAllTransactions() throws {
        try dbWriter.write { db in
            _ = try Transaction.deleteAll(db)
        }
    }
    
    func saveTag(_ tag: inout Tag) throws {
        try dbWriter.write { db in
            try tag.save(db)
        }
    }
    
    func deleteTag(id: Int64) throws {
        try dbWriter.write { db in
            _ = try Tag.deleteOne(db, id: id)
        }
    }
    
    func setTransactionTags(transaction: Transaction, tags: [Tag]) throws {
        try dbWriter.write { db in
            try TransactionTag.filter(TransactionTag.Columns.transactionID == transaction.id!).deleteAll(db)
            try tags.forEach({ tag in
                var tTag = TransactionTag(id: nil, transactionID: transaction.id!, tagID: tag.id!)
                try tTag.save(db)
            })
        }
    }
    
    func setTransactionsTags(transactions: [Transaction], tags: [Tag]) throws {
        try dbWriter.write { db in
            //TODO: This can be made faster
            for transaction in transactions {
                try TransactionTag.filter(TransactionTag.Columns.transactionID == transaction.id!).deleteAll(db)
                try tags.forEach({ tag in
                    var tTag = TransactionTag(id: nil, transactionID: transaction.id!, tagID: tag.id!)
                    try tTag.save(db)
                })
            }
        }
    }
    
    func saveBucket(_ bucket: inout Bucket) throws {
        try dbWriter.write { db in
            try bucket.save(db)
        }
    }
    
    func deleteBucket(id: Int64) throws {
        try dbWriter.write { db in
            _ = try Bucket.deleteOne(db, id: id)
        }
    }
    
    func deleteBuckets(ids: [Int64]) throws {
        try dbWriter.write { db in
            _ = try Bucket.deleteAll(db, ids: ids)
        }
    }
    
    func saveSchedule(_ schedule: inout Schedule) throws {
        try dbWriter.write { db in
            try schedule.save(db)
        }
    }
    
    func deleteSchedule(id: Int64) throws {
        try dbWriter.write { db in
            _ = try Schedule.deleteOne(db, id: id)
        }
    }
}

// MARK: - Database Access: Reads

extension AppDatabase {
    /// Provides a read-only access to the database
    var databaseReader: DatabaseReader {
        dbWriter
    }
    
    func resolve<Type: FetchableRecord>(_ query: QueryInterfaceRequest<Type>) -> [Type] {
        do {
            return try databaseReader.read { db in
                return try query.fetchAll(db)
            }
        } catch {
            print(error)
        }
        return []
    }
    
    func resolveOne<Type: FetchableRecord>(_ query: QueryInterfaceRequest<Type>) -> Type? {
        do {
            return try databaseReader.read { db in
                return try query.fetchOne(db)
            }
        } catch {
            print(error)
        }
        return nil
    }
}
