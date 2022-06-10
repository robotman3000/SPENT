//
//  SPENTDatabaseDocument.swift
//  macOS
//
//  Created by Eric Nims on 6/17/21.
//
import Foundation
import UniformTypeIdentifiers
import SwiftUI
import GRDB

private struct DatabaseQueueKey: EnvironmentKey {
    /// The default dbQueue is an empty in-memory database
    static var defaultValue: DatabaseQueue { DatabaseQueue() }
}

extension EnvironmentValues {
    var dbQueue: DatabaseQueue {
        get { self[DatabaseQueueKey.self] }
        set { self[DatabaseQueueKey.self] = newValue }
    }
}

extension UTType {
    static var spentDatabase: UTType {
        UTType(exportedAs: "io.github.robotman3000.spent-database")
    }
}

struct SPENTDatabaseDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.spentDatabase]
    static var writableContentTypes: [UTType] = [.spentDatabase]
   
    let bundleURL: URL
    let manager: DatabaseManager
    
    init() {
        print("Creating a new DB")
        bundleURL = SPENTDatabaseDocument.generateTempURL() // Path to the DB bundle
        
        let printQueries = UserDefaults.standard.bool(forKey: PreferenceKeys.debugQueries.rawValue)
        
        // TODO: Properly handle exceptions from here
        manager = try! SPENTDatabaseDocument.createDBManager(bundleURL: bundleURL, trace: true, isNewDatabase: true)
    }
    
    init(configuration: ReadConfiguration) throws {
        print("Reading existing")
        bundleURL = SPENTDatabaseDocument.generateTempURL() // Path to the DB bundle
        
        // Copy the file being opened to the temp location
        try configuration.file.write(to: self.bundleURL, options: .atomic, originalContentsURL: nil)
        
        let printQueries = UserDefaults.standard.bool(forKey: PreferenceKeys.debugQueries.rawValue)
        try self.manager = SPENTDatabaseDocument.createDBManager(bundleURL: bundleURL, trace: true)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // This function expects that the implementation will provide the file data
        // and let the system handle the actual I/O.
        // The problem is that GRDB doesn't support getting a Data object for a database
        // so we have to write the db to a temp file and return a FileWrapper for that file
        if let fileWrapper = configuration.existingFile {
            print("Saving to existing file from \(bundleURL.absoluteString)")
            try fileWrapper.read(from: bundleURL, options: .immediate)
            return fileWrapper
        }
        
        print("Saving DB from \(bundleURL.absoluteString)")
        return try FileWrapper(url: bundleURL, options: .immediate)
    }
    
    private static func generateTempURL() -> URL {
        return FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".spentdb")
    }
}

extension SPENTDatabaseDocument {
    private static func createDBManager(bundleURL: URL, trace: Bool = false, isNewDatabase: Bool = false) throws -> DatabaseManager {
        if !FileManager.default.fileExists(atPath: bundleURL.path) {
            try FileManager.default.createDirectory(atPath: bundleURL.path, withIntermediateDirectories: true, attributes: nil)
        }
        
        let dbURL = bundleURL.appendingPathComponent("db.sqlite")
        print("Using DB from path: \(dbURL.path)")
        let queue = try! DatabaseQueue(path: dbURL.path) // Open the DB
        
        let gitCommit: String = Bundle.main.object(forInfoDictionaryKey: "GIT_COMMIT_HASH") as? String ?? "(NIL)"
        if !isNewDatabase {
            // Verify the database is compatible with this version of the program
            if !checkDBCommit(database: queue) {
                print("WARNING: The current git hash is \(gitCommit), the hash in the database doesn't match.")
                // TODO: Abort loading the db if incompatible
            }
        }
        
        // Support debugging
        if trace {
            try queue.read { db in
                db.trace(options: .statement) { event in
                    print("SQL: \(event)")
                }
            }
        }
        
        // Create/Upgrade the schema to the latest version
        let migrator = SPENTDatabaseDocument.createDBMigrator()
        try! migrator.migrate(queue)
        
        // Create the utility views
        try SPENTDatabaseDocument.createDBViews(database: queue)
        
        // Update the DB commit
        setDBCommit(database: queue, commit: gitCommit)
        return DatabaseManager(dbQueue: queue)
    }
    
    private static func createDBMigrator() -> DatabaseMigrator {
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
        
        migrator.registerMigration("Bucket Categories", migrate: { db in
            try db.alter(table: "Buckets") { t in
                t.add(column: "Category", .text).notNull().defaults(to: "")
            }
        })
        
        // Migrations for future application versions will be inserted here:
        // migrator.registerMigration(...) { db in
        //     ...
        // }
        
        return migrator
    }
    
    private static func checkDBCommit(database: DatabaseQueue) -> Bool {
        do {
            // Check the saved commit hash against ours before handing the raw db to the db store
            let config = try database.read { db in
                try AppConfiguration.fetch(db)
            }
            let currentHash = Bundle.main.object(forInfoDictionaryKey: "GIT_COMMIT_HASH") as? String ?? "1234567890"
            print("DB Version: \(SPENT.DB_VERSION), Loaded Version: \(config.dbVersion)")
            print("\(config.commitHash) vs. \(currentHash)")
            if config.commitHash == currentHash {
                print("Hash matched")
                return true
            }
        } catch {
            print(error)
        }
        print("Hash didn't match")
        
        return false
    }
    
    private static func setDBCommit(database: DatabaseQueue, commit: String){
        do {
            try database.write { db in
                var config = try AppConfiguration.fetch(db)
                
                // Update some config values
                try config.updateChanges(db) {
                    $0.commitHash = commit
                    $0.dbVersion = SPENT.DB_VERSION
                }
            }
        } catch {
            print("Failed to update database commit hash")
            print(error)
        }
    }
    
    private static func createDBViews(database: DatabaseQueue) throws {
        try database.write { db in
            // The running balance column for all transactions grouped by each account
            try db.execute(sql: """
            CREATE TEMPORARY VIEW "AccountRunningBalance" AS
                SELECT SUM(DailyChange) OVER win1 AS "RunningBalance", AccountID, TransactionID FROM (
                    SELECT SUM(Amount) AS "DailyChange", PostDate, AccountID, Id AS "TransactionID" FROM Transactions
                    WHERE PostDate IS NOT NULL
                    AND Transactions.Id NOT IN (SELECT TransactionID FROM SplitTransactions)
                    AND Transactions.Status IN (5, 6)
                    GROUP BY AccountID, date(PostDate)
                ) WINDOW win1 AS (PARTITION BY AccountID ROWS UNBOUNDED PRECEDING)
            """)
            
            // The current balance of the accounts
            try db.execute(sql: """
            CREATE TEMPORARY VIEW "AccountBalance" AS
                WITH
                "posted" ("Posted", "id") AS (
                    SELECT SUM(Amount), AccountID FROM Transactions WHERE Status IN (5, 6) GROUP BY AccountID
                ),
                "available" ("Available", "id") AS (
                    SELECT SUM(Amount), AccountID FROM Transactions WHERE Status > 3 GROUP BY AccountID
                ),
                "allocatable" ("Allocatable", "id") AS (
                    SELECT SUM(Amount), AccountID FROM Transactions WHERE Status <> 0 AND BucketID IS NULL GROUP BY AccountID
                ),
                "estimated" ("Estimated", "id") AS (
                    SELECT SUM(Amount), AccountID FROM Transactions WHERE Status <> 0 GROUP BY AccountID
                )
                SELECT id, IFNULL(Posted, 0) AS "Posted", IFNULL(Available, 0) AS "Available", IFNULL(Allocatable, 0) AS "Allocatable", IFNULL(Estimated, 0) AS "Estimated"
                FROM Accounts LEFT JOIN posted USING (id) LEFT JOIN available USING (id) LEFT JOIN allocatable USING (id) LEFT JOIN estimated USING (id)
            """)
            
            // The list of all posible account-bucket combinations
            try db.execute(sql: """
            CREATE TEMPORARY VIEW "AllBuckets" AS
                SELECT a.id AS "AccountID", b.id AS "BucketID" FROM Buckets b CROSS JOIN Accounts a
            """)
            
            // The current balance of the buckets
            try db.execute(sql: """
            CREATE TEMPORARY VIEW "BucketBalance" AS
                WITH
                "posted" ("Posted", "AccountID", "BucketID") AS (
                    SELECT SUM(Amount), AccountID, BucketID FROM Transactions WHERE BucketID IS NOT NULL AND Status IN (5, 6) GROUP BY AccountID, BucketID
                ),
                "available" ("Available", "AccountID", "BucketID") AS (
                    SELECT SUM(Amount), AccountID, BucketID FROM Transactions WHERE BucketID IS NOT NULL AND Status <> 0 GROUP BY AccountID, BucketID
                )
                SELECT BucketID, AccountID, IFNULL(Posted, 0) AS "Posted", IFNULL(Available, 0) AS "Available" FROM AllBuckets
                JOIN posted USING (AccountID, BucketID) JOIN available USING (AccountID, BucketID)
            """)
            
            // The datatype of each transaction
            try db.execute(sql: """
            CREATE TEMPORARY VIEW "TransactionType" AS
                SELECT Transactions.id, Transfers.id AS "TransferID", SplitTransactions.id AS "SplitID", CASE
                    WHEN (SourceTransactionID IS NOT NULL OR DestinationTransactionID IS NOT NULL) THEN 'Transfer'
                    WHEN (TransactionID IS NOT NULL OR SplitHeadTransactionID IS NOT NULL) THEN 'Split'
                    WHEN (Amount < 0) THEN 'Withdrawal'
                    WHEN (Amount >= 0) THEN 'Deposit'
                    ELSE 'Transaction' END AS "Type"
                FROM Transactions
                LEFT JOIN Transfers ON SourceTransactionID == Transactions.id OR DestinationTransactionID == Transactions.id
                LEFT JOIN SplitTransactions ON TransactionID == Transactions.id OR SplitHeadTransactionID == Transactions.id
            """)
        }
    }
}

// Preview Support
extension SPENTDatabaseDocument {
    /// Returns an empty in-memory database for the application.
    static func emptyDatabaseQueue() -> DatabaseQueue {
        let dbQueue = DatabaseQueue()
    
        try! createDBMigrator().migrate(dbQueue)
       return dbQueue
    }
    
    /// Returns an in-memory database that contains the test data.
    static func populatedDatabaseQueue() -> DatabaseQueue {
        let dbQueue = emptyDatabaseQueue()
        try! dbQueue.write { db in
            // TODO: Generate the test data
        }
        return dbQueue
    }
}

