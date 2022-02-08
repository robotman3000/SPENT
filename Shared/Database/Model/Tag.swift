//
//  Tag.swift
//  SPENT
//
//  Created by Eric Nims on 5/14/21.
//

import Foundation
import GRDB

struct Tag: Identifiable, Codable, Hashable {
    var id: Int64?
    var name: String
}

// SQL Database support
extension Tag: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "Tags"
    
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

extension Tag {
    static let transactions = hasMany(Transaction.self, through: hasMany(TransactionTagMapping.self), using: TransactionTagMapping.transaction)
}
