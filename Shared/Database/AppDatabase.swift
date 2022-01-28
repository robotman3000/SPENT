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
    
    static var DB_VERSION: Int64 = 6
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
    
    init(path: URL, trace: Bool = false) throws {
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
            try db.create(table: "Accounts") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("Name", .text).notNull().unique()
            }
            
            try db.create(table: "Buckets") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("Name", .text).notNull().unique()
            }
            
            try db.create(table: "Transactions") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("Status", .integer).notNull()
                t.column("Amount", .integer).notNull()
                t.column("Payee", .text).notNull().defaults(to: "")
                t.column("Memo", .text).notNull().defaults(to: "")
                t.column("EntryDate", .date).notNull()
                t.column("PostDate", .date)
                t.column("BucketID", .integer).references("Buckets", onDelete: .restrict) // Prevent deleting a bucket with transactions
                t.column("AccountID", .integer).references("Accounts", onDelete: .restrict).notNull() // Prevent deleting an account with transactions
            }
            
            try db.create(table: "Tags") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("Name", .text).notNull().unique()
            }
            
            try db.create(table: "TransactionTemplates") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("TemplateData", .text).notNull()
            }
            
            // Create attachments table
            try db.create(table: "Attachments") { t in
                t.autoIncrementedPrimaryKey("id")
                // Prevent duplicate filenames for information clarity
                t.column("Filename", .text).notNull().unique()
                
                // The hash is for file security/integrity
                // The unique helps ensure that duplicate files can't be added
                t.column("SHA256", .text).notNull().unique()
            }
            
            try db.create(table: "TransactionTagMap") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("TransactionID", .integer).notNull().references("Transactions", onDelete: .cascade) // Delete the assignment with the transaction
                t.column("TagID", .integer).notNull().references("Tags", onDelete: .restrict) // Prevent deleting a tag that is assigned to transactions
                t.uniqueKey(["TransactionID", "TagID"], onConflict: .replace)
            }
            
            // Create attachment assignments
            try db.create(table: "TransactionAttachmentMap") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("TransactionID", .integer).notNull().references("Transactions", onDelete: .restrict) // Prevent deleting a transaction with attachments; This will require the program to remove the attachments first, thus reducing the possibility for "loose" attachements in the db
                
                // We can have may attachents for a transaction but each attachment can have only one transaction
                // so we prevent the attachment id from being used more than once
                t.column("AttachmentID", .integer).unique().notNull().references("Attachments", onDelete: .cascade) // Delete the assignment with the attachment
            }
            
            try db.create(table: "Transfers") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("SourceTransactionID", .integer).references("Transactions", onDelete: .cascade).notNull()
                t.column("DestinationTransactionID", .integer).references("Transactions", onDelete: .cascade).notNull()
            }
            
            try db.create(table: "SplitTransactions") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("TransactionID", .integer).references("Transactions", onDelete: .cascade).notNull().unique()
                t.column("SplitHeadTransactionID", .integer).references("Transactions", onDelete: .restrict).notNull()
                t.column("SplitUUID", .text).notNull()
            }
            
            
//            // VIEW - Transaction Ancestors
//            try db.execute(sql: """
//                CREATE VIEW transactionAncestors AS
//                SELECT t.id AS id,
//                       b1.V_Ancestor AS SourceAccount,
//                       b2.V_Ancestor AS DestAccount,
//                       IFNULL(b1.V_Ancestor == b2.V_Ancestor, False) AS isAllocation
//                FROM Transactions t
//                LEFT JOIN Buckets b1 ON SourceBucket = b1.id
//                LEFT JOIN Buckets b2 ON DestBucket = b2.id
//            """)

//            // VIEW - Transaction Amounts (and other useful columns)
//            try db.execute(sql: """
//                CREATE VIEW transactionAmounts AS
//                SELECT id,
//                       Status,
//                       -1*Amount AS TrueAmount,
//                       SourceBucket AS Bucket,
//                       t.SourceAccount AS Account,
//                       IFNULL(SourcePostDate, TransDate) AS "Date",
//                       t.isAllocation
//                FROM Transactions
//                JOIN transactionAncestors t USING (id)
//                WHERE SourceBucket IN (SELECT id FROM Buckets)
//                UNION ALL
//                SELECT id,
//                       Status,
//                       Amount AS TrueAmount,
//                       DestBucket AS Bucket,
//                       t.DestAccount AS Account,
//                       IFNULL(DestPostDate, TransDate) AS "Date",
//                       t.isAllocation
//                FROM Transactions
//                JOIN transactionAncestors t USING (id)
//                WHERE DestBucket IN (SELECT id FROM Buckets)
//            """)
            
//            // VIEW - Transaction Running Balance
//            try db.execute(sql: """
//                CREATE VIEW transactionBalance AS
//                SELECT
//                       ra.id,
//                       ra.Bucket,
//                       ra.Account,
//                       SUM(TrueAmount) FILTER (WHERE Status IN (4, 5, 6)) OVER win1 AS pRunning,
//                       SUM(TrueAmount) FILTER (WHERE Status IN (1, 3)) OVER win1 AS aRunning
//                FROM transactionAmounts ra
//                LEFT JOIN Buckets bt ON bt.id = ra.Bucket
//                WHERE ra.isAllocation == false
//                WINDOW win1 AS (PARTITION BY V_Ancestor ORDER BY "Date", ra.id ASC ROWS UNBOUNDED PRECEDING)
//                ORDER BY "Date" ASC
//            """)
            
//            // VIEW - Bucket Balance
//            try db.execute(sql: """
//                CREATE VIEW bucketBalance AS
//                SELECT DISTINCT
//                        r.Bucket AS id,
//                        IFNULL(available, 0)+IFNULL(posted, 0) AS "available",
//                        IFNULL(posted, 0) AS "posted"
//                FROM transactionAmounts r
//                LEFT JOIN (
//                    SELECT SUM(TrueAmount) AS "available", Bucket
//                    FROM transactionAmounts
//                    WHERE Status IN (1, 3)
//                    GROUP BY Bucket
//                ) USING (Bucket)
//                LEFT JOIN (
//                    SELECT SUM(TrueAmount) AS "posted", Bucket
//                    FROM transactionAmounts
//                    WHERE Status IN (4, 5, 6)
//                    GROUP BY Bucket
//                ) USING (Bucket)
//            """)
//
//            // VIEW - All Transactions (View optimized for use by the main transactions list)
//            try db.execute(sql: """
//                CREATE VIEW allTransactions AS
//                SELECT
//                    t.id, t.Status, t.SourceBucket, t.DestBucket, t.Memo, t.Payee, t."Group", t.V_Type,
//                    ta.TrueAmount AS "Amount", ta.Bucket, ta.Account, ta."Date", ta.isAllocation,
//                    b.pRunning AS "PostedRunning", b.aRunning AS "AvailableRunning"
//                FROM Transactions t
//                JOIN transactionAmounts ta USING (id)
//                LEFT JOIN transactionBalance b USING (id, Account)
//                ORDER BY t.id
//            """)
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
    
    func transaction(_ query: (_ db: Database) throws -> Void) throws {
        try dbWriter.write { db in
            try query(db)
        }
    }
}

// MARK: - Database Access: Reads

extension AppDatabase {
    /// Provides a read-only access to the database
    var databaseReader: DatabaseReader {
        dbWriter
    }
    
    // TODO: Make this a throwing function
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
