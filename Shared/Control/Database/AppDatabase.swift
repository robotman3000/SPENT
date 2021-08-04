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

// Let SwiftUI views access the database through the SwiftUI environment
private struct AppDatabaseKey: EnvironmentKey {
    static let defaultValue: AppDatabase? = nil
}

extension EnvironmentValues {
    var appDatabase: AppDatabase? {
        get { return self[AppDatabaseKey.self] }
        set { self[AppDatabaseKey.self] = newValue }
    }
}

/// AppDatabase lets the application access the database.
///
/// It applies the pratices recommended at
/// https://github.com/groue/GRDB.swift/blob/master/Documentation/GoodPracticesForDesigningRecordTypes.md
struct AppDatabase {
    init(){
        do {
            print("Using Memory DB")
            self.dbWriter = DatabaseQueue()
            try migrator.migrate(dbWriter)
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
    
    init(path: URL, trace: Bool = true) {
        do {
            let newURL = path.appendingPathComponent("db.sqlite")
            print("Using DB from path: \(newURL.absoluteString)")
            self.dbWriter = try DatabaseQueue(path: newURL.absoluteString)
            if trace {
                try databaseReader.read { db in
                    db.trace(options: .statement) { event in
                        print("SQL: \(event)")
                    }
                }
            }
            try migrator.migrate(dbWriter)
        }
        catch {
//             Replace this implementation with code to handle the error appropriately.
//             fatalError() causes the application to generate a crash log and terminate.
//
//             Typical reasons for an error here include:
//             * The parent directory cannot be created, or disallows writing.
//             * The database is not accessible, due to permissions or data protection when the device is locked.
//             * The device is out of space.
//             * The database could not be migrated to its latest schema version.
//             Check the error message to determine what the actual problem was.
            fatalError("Unresolved error \(error)")
        }
    }
    
    init(_ fileWrapper: FileWrapper, tempURL: URL){
        do {
            print("Using DB from FileWrapper")
            self.dbWriter = try DatabaseQueue(fileWrapper: fileWrapper, tempURL: tempURL)
            try migrator.migrate(dbWriter)
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
            }
            
            try db.create(table: "Schedules") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("Name", .text).notNull()
                t.column("Type", .integer).notNull()
                t.column("Rule", .integer).notNull()
                t.column("CustomRule", .blob)
                t.column("MarkerID", .integer).notNull().references("Tags") // onDelete: Default
                t.column("Memo", .text).notNull().defaults(to: "")
                //t.column("LastRun", .date)
            }
            
            try db.create(table: "Buckets") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("Name", .text).notNull().unique()
                t.column("Parent", .integer).references("Buckets", onDelete: .cascade)
                t.column("Ancestor", .integer).references("Buckets", onDelete: .cascade)
                t.column("BudgetID", .text).references("Schedules") // onDelete: Default
                t.column("Memo", .text).notNull().defaults(to: "")
            }
            
            try db.create(table: "Transactions") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("Status", .integer).notNull()
                t.column("TransDate", .date).notNull()
                t.column("PostDate", .date)
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
                t.column("Group", .text)
            }
            
            try db.create(table: "TransactionTags") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("TransactionID", .integer).notNull().references("Transactions", onDelete: .cascade)
                
                // It should not be possible to delete a tag assigned to a transaction by cascade because
                // the schedules table depends on the presence of tags it has assigned.
                // TODO: Use program logic to determin if a tag can be deleted
                t.column("TagID", .integer).notNull().references("Tags")
                t.uniqueKey(["TransactionID", "TagID"], onConflict: .replace)
            }
            
            // Create recipts table
            try db.create(table: "Recipts") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("Blob", .blob).notNull()
            }
            
            // Create recipts assignments
            try db.create(table: "TransactionRecipts") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("TransactionID", .integer).notNull().references("Transactions", onDelete: .cascade)
                t.column("ReciptID", .integer).notNull().references("Recipts", onDelete: .cascade)
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
//                db.trace(options: .statement) { event in
//                    print("SQL: \(event)")
//                }
                return try query.fetchOne(db)
            }
        } catch {
            print(error)
        }
        return nil
    }
    
    func getBucketFromID(_ bucketID: Int64?) -> Bucket? {
        guard bucketID != nil else {
            return nil
        }
        
        do {
            return try databaseReader.read { db in
                return try Bucket.filter(id: bucketID!).fetchOne(db)
            }
        } catch {
            print(error)
        }
        return nil
    }
    
    func getTransactionTags(_ transaction: Transaction) -> [Tag] {
        return resolve(transaction.tags)
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
            var result = try bucket.tree.fetchAll(db)
            result.append(bucket)
            return result
        }
    }
    

}
