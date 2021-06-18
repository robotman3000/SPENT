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
    var scheduleType: ScheduleType
    var rule: ScheduleRule
    var customRule: String? // TODO: Change this to the correct type
    var markerID: Int64
    var memo: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, name = "Name", scheduleType = "Type", rule = "Rule", customRule = "CustomRule", markerID = "MarkerID", memo = "Memo"
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
        static let scheduleType = Column(CodingKeys.scheduleType)
        static let rule = Column(CodingKeys.rule)
        static let customRule = Column(CodingKeys.customRule)
        static let markerID = Column(CodingKeys.markerID)
        static let memo = Column(CodingKeys.memo)
    }
}

extension Schedule {
    static let marker = belongsTo(Tag.self, using: ForeignKey(["MarkerID"]))
    var source: QueryInterfaceRequest<Tag> {
        request(for: Schedule.marker)
    }
}
 
// Status Enum
extension Schedule {
    enum ScheduleType: Int, Codable, CaseIterable, Identifiable {
        case OneTime
        case Recurring
        
        var id: String { self.getStringName() }
        
        func getStringName() -> String{
            switch self {
            case .OneTime: return "Once"
            case .Recurring: return "Recurring"
            }
        }
    }
}
extension Schedule.ScheduleType: DatabaseValueConvertible { }

// Transaction Type Enum
extension Schedule {
    enum ScheduleRule: Int, Codable, CaseIterable, Identifiable {
        /// Always triggers
        case Anytime
        
        /// Never triggers
        case Never
        
        /// Uses the JSON data in the CustomRule colum
        case Custom
        
        var id: String { self.getStringName() }
        
        func getStringName() -> String {
            switch self {
            case .Anytime: return "Anytime"
            case .Never: return "Disabled"
            case .Custom: return "User Defined"
            }
        }
    }
}
extension Schedule.ScheduleRule: DatabaseValueConvertible { }
