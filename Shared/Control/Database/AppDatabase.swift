//
//  AppDatabase.swift
//  SPENT
//
//  Created by Eric Nims on 5/12/21.
//

import Combine
import GRDB
import Foundation

/// AppDatabase lets the application access the database.
///
/// It applies the pratices recommended at
/// https://github.com/groue/GRDB.swift/blob/master/Documentation/GoodPracticesForDesigningRecordTypes.md
struct AppDatabase {
    /// Creates an `AppDatabase`, and make sure the database schema is ready.
    init(_ dbWriter: DatabaseWriter) throws {
        self.dbWriter = dbWriter
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
            
            // Create a table
            // See https://github.com/groue/GRDB.swift#create-tables
            try db.create(table: "Buckets") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("Name", .text).notNull().unique()
                t.column("Parent", .integer).references("Buckets")
                t.column("Ancestor", .integer).references("Buckets")
            }
            
            try db.create(table: "Transactions") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("Status", .integer).notNull()
                t.column("TransDate", .date).notNull()
                t.column("PostDate", .date)
                t.column("Amount", .double).notNull().check {
                    // While things won't break with negative values, we don't allow them in the DB because it would start to get confusing to the end user
                    // I.E Negatives don't really make sense here
                    $0 >= 0
                }
                t.column("SourceBucket", .integer).notNull().references("Buckets")
                t.column("DestBucket", .integer).notNull().references("Buckets")
                t.column("Memo", .text)
                t.column("Payee", .text)
            }
            
            try db.create(table: "Tags") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("Name", .text).notNull().unique()
            }
            
            try db.create(table: "TransactionTags") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("TransactionID", .integer).notNull().references("Transactions")
                t.column("TagID", .integer).notNull().references("Tags")
                t.uniqueKey(["TransactionID", "TagID"])
            }
            
            try db.execute(sql: "INSERT INTO Transactions VALUES (-1, \"ROOT\", NULL, NULL)")
        }
        
        migrator.registerMigration("v1.1") { db in
            print("Migration 1.1")
            // Change Transaction.Amount to an integer
            
            /*
             ALTER TABLE Transactions
             ADD COLUMN IntAmount INTEGER NOT NULL DEFAULT 0;
             UPDATE Transactions
             SET IntAmount = round(Amount*100)
             */
            
            try db.alter(table: "Transactions") { t in
                t.add(column: "IntAmount", .integer).notNull().defaults(to: 0)
            }
            try db.execute(sql: "UPDATE Transactions SET IntAmount = round(Amount*100)")
            
            // Now we drop the old column
            try db.create(table: "TransactionsNew") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("Status", .integer).notNull()
                t.column("TransDate", .date).notNull()
                t.column("PostDate", .date)
                t.column("IntAmount", .integer).notNull().check {
                    // While things won't break with negative values, we don't allow them in the DB because it would start to get confusing to the end user
                    // I.E Negatives don't really make sense here
                    $0 >= 0
                }
                t.column("SourceBucket", .integer).notNull().references("Buckets")
                t.column("DestBucket", .integer).notNull().references("Buckets")
                t.column("Memo", .text)
                t.column("Payee", .text)
            }
            try db.execute(sql: "INSERT INTO TransactionsNew SELECT id, Status, TransDate, PostDate, IntAmount, SourceBucket, DestBucket, Memo, Payee FROM Transactions")
            
            try db.drop(table: "Transactions")
            try db.alter(table: "TransactionsNew") { t in
                t.rename(column: "IntAmount", to: "Amount")
            }
            try db.rename(table: "TransactionsNew", to: "Transactions")
        }
        
        migrator.registerMigration("v1.2") { db in
            db.trace(options: .statement) { event in
                print("SQL: \(event)")
            }
            
            // *** Eliminate the "Root" bucket ***
            
            // Allow a null transaction source and destination and disable nulls in the memo
            try db.create(table: "TransactionsNew") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("Status", .integer).notNull()
                t.column("TransDate", .date).notNull()
                t.column("PostDate", .date)
                t.column("Amount", .integer).notNull().check {
                    // While things won't break with negative values, we don't allow them in the DB because it would start to get confusing to the end user
                    // I.E Negatives don't really make sense here
                    $0 >= 0
                }
                t.column("SourceBucket", .integer).references("Buckets")
                t.column("DestBucket", .integer).references("Buckets")
                t.column("Memo", .text).notNull().defaults(to: "")
                t.column("Payee", .text)
            }
            
            // Eliminate all null memos
            try db.execute(sql: "UPDATE Transactions SET Memo = IfNull(Memo,'')")
            
            try db.execute(sql: "INSERT INTO TransactionsNew SELECT * FROM Transactions")
            
            try db.drop(table: "Transactions")
            try db.rename(table: "TransactionsNew", to: "Transactions")
            
            // Change all -1's in the source and destination to be null
            try db.execute(sql: "UPDATE Transactions SET SourceBucket = NULL WHERE SourceBucket = -1")
            try db.execute(sql: "UPDATE Transactions SET DestBucket = NULL WHERE DestBucket = -1")
            
            // Nix the -1 values and the root bucket in the buckets table
            try db.execute(sql: "UPDATE Buckets SET Parent = NULL WHERE Parent = -1")
            try db.execute(sql: "UPDATE Buckets SET Ancestor = NULL WHERE Ancestor = -1")
            try db.execute(sql: "DELETE FROM Buckets WHERE id = -1")
            
            
            // *** Database support for split/grouped tansactions ***
            
            // Alter Transactions table to add the Group ID
            try db.alter(table: "Transactions") { t in
                t.add(column: "Group", .blob)
            }
            
            // *** Additional storage colums for the user ***
            
            // Alter Buckets table to add Memo
            try db.alter(table: "Buckets") { t in
                t.add(column: "Memo", .text).notNull().defaults(to: "")
            }
            
            // Alter Tag to add Memo
            try db.alter(table: "Tags") { t in
                t.add(column: "Memo", .text).notNull().defaults(to: "")
            }
        }
        
        //migrator.registerMigration("v2") { db in
            // Rename all columns and tables
        
            // Recipts storage table
            // Recipts assignment storage table
            // Schedules table
        //}

        
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
    
    /// Saves (inserts or updates) a player. When the method returns, the
    /// player is present in the database, and its id is not nil.
    func saveTransaction(_ player: inout Transaction) throws {
//        if player.name.isEmpty {
//            throw ValidationError.missingName
//        }
        try dbWriter.write { db in
            try player.save(db)
        }
    }
    
    /// Delete the specified players
    func deleteTransactions(ids: [Int64]) throws {
        try dbWriter.write { db in
            _ = try Transaction.deleteAll(db, keys: ids)
        }
    }
    
    /// Delete all players
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
}

// MARK: - Database Access: Reads

extension AppDatabase {
    /// Provides a read-only access to the database
    var databaseReader: DatabaseReader {
        dbWriter
    }
    
    func getTag(_ id: Int64?) throws -> Tag? {
        guard id != nil else {
            return nil
        }
        
        return try databaseReader.read { db in
            try Tag.fetchOne(db, id: id!)
        }
    }
    
    private func getTreeAtBucket(_ bucket: Bucket) throws -> [Bucket]{
        return try databaseReader.read { db in
            try bucket.tree.fetchAll(db)
        }
    }
    
    func getPostedBalance(_ bucket: Bucket) throws -> Int {
        return try getBalanceQuery(buckets: [bucket], statusTypes: Transaction.StatusTypes.allCases.filter({status in
            status.rawValue > 2
        }))
    }
    
    func getAvailableBalance(_ bucket: Bucket) throws -> Int {
        return try getBalanceQuery(buckets: [bucket], statusTypes: Transaction.StatusTypes.allCases.filter({status in
            status.rawValue != 0
        }))
    }
    
    func getPostedTreeBalance(_ bucket: Bucket) throws -> Int {
        return try getBalanceQuery(buckets: getTreeAtBucket(bucket), statusTypes: Transaction.StatusTypes.allCases.filter({status in
            status.rawValue > 2
        }))
    }
    
    func getAvailableTreeBalance(_ bucket: Bucket) throws -> Int {
        return try getBalanceQuery(buckets: getTreeAtBucket(bucket), statusTypes: Transaction.StatusTypes.allCases.filter({status in
            status.rawValue != 0
        }))
    }
    
    private func getBalanceQuery(buckets: [Bucket], statusTypes: [Transaction.StatusTypes]) throws -> Int {
        var statusIDs: [Int] = []
        for status in statusTypes {
            statusIDs.append(status.rawValue)
        }
        let statusStr: String = statusIDs.map({ val in return "\(val)" }).joined(separator: ", ")
        
        var bucketIDs: [Int64] = []
        for bucket in buckets {
            if bucket.id != nil {
                bucketIDs.append(bucket.id!)
            }
        }
        let bucketStr: String = bucketIDs.map({ val in return "\(val)" }).joined(separator: ", ")
        
        var balance: Int = 0
        try databaseReader.read { db in
            db.trace(options: .statement) { event in
                print("SQL: \(event)")
            }
            print(statusStr)
            if let row = try Row.fetchOne(db, sql: """
                    SELECT IFNULL(SUM(Amount), 0) AS \"Amount\" FROM (
                        SELECT -1*SUM(Amount) AS \"Amount\" FROM Transactions WHERE SourceBucket IN (\(bucketStr)) AND Status IN (\(statusStr))
                    
                        UNION ALL
                    
                        SELECT SUM(Amount) AS \"Amount\" FROM Transactions WHERE DestBucket IN (\(bucketStr)) AND Status IN (\(statusStr))
                    )
            """, arguments: []) {
                print(row)
                balance = row["Amount"]
            }
        }
        
        return balance
    }
    
//    @classmethod
//    def getPostedBalance(self, connection, bucket: 'Bucket', includeChildren: bool = False) -> float:
//        return self._calculateBalance_(connection, bucket, True, includeChildren)
//
//    @classmethod
//    def getAvailableBalance(self, connection, bucket: 'Bucket', includeChildren: bool = False) -> float:
//        return self._calculateBalance_(connection, bucket, False, includeChildren)
//
//    @classmethod
//    def _calculateBalance_(self, connection, bucket: 'Bucket', posted: bool = False, includeChildren: bool = False) -> float:
//        ids = []
//        if includeChildren:
//            ids = self.getAllBucketChildrenID(connection, bucket)
//        ids.append(bucket.getID())  # We can't forget ourself
//        idStr = ", ".join(map(str, ids))
//
//        statusStr = ""
//        if posted:
//            statusStr = "AND Status > 2"
//
//        query = "
//
//    SELECT IFNULL(SUM(Amount), 0) AS \"Amount\" FROM (
//        SELECT -1*SUM(Amount) AS \"Amount\" FROM Transactions WHERE SourceBucket IN (%s) %s AND Status != 0
//
//        UNION ALL
//
//        SELECT SUM(Amount) AS \"Amount\" FROM Transactions WHERE DestBucket IN (%s) %s AND Status != 0
//    )" % (
//        idStr, statusStr, idStr, statusStr)
//        column = "Amount"
//
//        result = connection.execute(query)
//        if len(result) > 0:
//            return round(float(result[0][column]), 2)
//        return 0
}

extension AppDatabase {
    /// The database for the application
    //static let shared = loadDB()
    
    static func loadDB() -> AppDatabase {
        do {
            // Pick a folder for storing the SQLite database, as well as
            // the various temporary files created during normal database
            // operations (https://sqlite.org/tempfiles.html).
            let fileManager = FileManager()
            let folderURL = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("database", isDirectory: true)

            // Support for tests: delete the database if requested
            if CommandLine.arguments.contains("-reset") {
                print("Resetting DB as requested")
                try? fileManager.removeItem(at: folderURL)
            }
            
            // Create the database folder if needed
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            
            // Connect to a database on disk
            // See https://github.com/groue/GRDB.swift/blob/master/README.md#database-connections
            let dbURL = folderURL.appendingPathComponent("db.sqlite")
            
            print("Using DB at: \(dbURL.absoluteString)")
            let dbPool = try DatabasePool(path: dbURL.path)
            
            // Create the AppDatabase
            let appDatabase = try AppDatabase(dbPool)
            
            return appDatabase
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate.
            //
            // Typical reasons for an error here include:
            // * The parent directory cannot be created, or disallows writing.
            // * The database is not accessible, due to permissions or data protection when the device is locked.
            // * The device is out of space.
            // * The database could not be migrated to its latest schema version.
            // Check the error message to determine what the actual problem was.
            fatalError("Unresolved error \(error)")
        }
    }
}
