//
//  TransactionTemplate.swift
//  macOS
//
//  Created by Eric Nims on 9/16/21.
//

import Foundation
import GRDB

struct DBTransactionTemplate: Identifiable, Codable, Hashable {
    var id: Int64?
    var template: String
    
    private enum CodingKeys: String, CodingKey {
        case id, template = "Template"
    }
}

// SQL Database support
extension DBTransactionTemplate: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "TransactionTemplates"
    
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
    
    // Define database columns from CodingKeys
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let template = Column(CodingKeys.template)
    }
}
