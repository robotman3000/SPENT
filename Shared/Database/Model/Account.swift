//
//  Account.swift
//  SPENT
//
//  Created by Eric Nims on 1/27/22.
//

import Foundation
import GRDB

struct Account: Identifiable, Codable, Hashable {
    var id: Int64?
    var name: String
}

// SQL Database support
extension Account: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "Accounts"
    
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
    
    // Define database columns from CodingKeys
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
    }
}
