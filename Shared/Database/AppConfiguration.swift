//
//  AppConfiguration.swift
//  SPENT
//
//  Created by Eric Nims on 8/26/21.
//

import GRDB
import Foundation

struct AppConfiguration: Codable {
    // Support for the single row guarantee
    private var id = 1
    
    // The configuration properties
    var commitHash: String
    
    var dbVersion: Int64
    // ... other properties
}

extension AppConfiguration {
    /// The default configuration
    static let `default` = AppConfiguration(commitHash: "1029384756", dbVersion: -2)
}

extension AppConfiguration: FetchableRecord, PersistableRecord {
    // Customize the default PersistableRecord behavior
    func update(_ db: Database, columns: Set<String>) throws {
        do {
            try performUpdate(db, columns: columns)
        } catch PersistenceError.recordNotFound {
            // No row was updated: perform an insert
            try performInsert(db)
        }
    }
    /// Returns the persisted configuration, or the default one if the
    /// database table is empty.
    static func fetch(_ db: Database) throws -> AppConfiguration {
        try fetchOne(db) ?? .default
    }
}
