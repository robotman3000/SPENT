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

extension DBTransactionTemplate {
    static func newTemplate() -> DBTransactionTemplate {
        // This should never actually fail so we just ignore the exception
        // If it does the runtime crash will be useful
        let jsonData = try! JSONEncoder().encode(TransactionTemplate(name: "", memo: "", amount: 0, tags: []))
        return DBTransactionTemplate(id: nil, template: String(data: jsonData, encoding: .utf8)!)
    }
    
    func decodeTemplate() throws -> TransactionTemplate? {
        if let jsonData = template.data(using: .utf8) {
            let decoder = JSONDecoder()
            return try decoder.decode(TransactionTemplate.self, from: jsonData)
        }
        return nil
    }
}
