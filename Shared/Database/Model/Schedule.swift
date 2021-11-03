//
//  Schedule.swift
//  SPENT
//
//  Created by Eric Nims on 6/17/21.
//

import Foundation
import GRDB

struct Schedule: Identifiable, Codable, Hashable {
    var id: Int64?
    var name: String
    var memo: String = ""
    var templateID: Int64
    var isFavorite: Bool = false
    
    private enum CodingKeys: String, CodingKey {
        case id, name = "Name", memo = "Memo", templateID = "Template", isFavorite = "Favorite"
    }
}

// SQL Database support
extension Schedule: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "Schedules"
    
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
    
    // Define database columns from CodingKeys
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let memo = Column(CodingKeys.memo)
        static let template = Column(CodingKeys.templateID)
        static let favorite = Column(CodingKeys.isFavorite)
    }
}

//extension Schedule {
//    static let template = belongsTo(TransactionTemplate.self, using: ForeignKey(["Template"]))
//    var template: QueryInterfaceRequest<TransactionTemplate> {
//        request(for: Schedule.template)
//    }
//}

extension Schedule {
    static func newSchedule() -> Schedule {
        return Schedule(id: nil, name: "", templateID: -1)
    }
}
