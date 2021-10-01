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
    var memo: String = ""
    var color: String = "#8c8c8c"
    var isFavorite: Bool = false
    
    private enum CodingKeys: String, CodingKey {
        case id, name = "Name", memo = "Memo", color = "Color", isFavorite = "Favorite"
    }
}

extension Tag {
    static let transactions = hasMany(Transaction.self, through: hasMany(TransactionTag.self, key: "TagID"), using: TransactionTag.transaction)
    var transactions: QueryInterfaceRequest<Transaction> {
        request(for: Tag.transactions)
    }
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
        static let memo = Column(CodingKeys.memo)
        static let color = Column(CodingKeys.color)
        static let favorite = Column(CodingKeys.isFavorite)
    }
}

extension Tag {
    static func newTag() -> Tag {
        return Tag(id: nil, name: "", memo: "")
    }
    
    //TODO: String color to Color object
}
