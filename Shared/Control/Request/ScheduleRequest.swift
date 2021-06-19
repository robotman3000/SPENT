//
//  ScheduleRequest.swift
//  SPENT
//
//  Created by Eric Nims on 6/19/21.
//

import Foundation
import GRDB

/// Make `ScheduleREquest` able to be used with the `@Query` property wrapper.
struct ScheduleRequest: Queryable {
    static func == (lhs: ScheduleRequest, rhs: ScheduleRequest) -> Bool {
        return lhs.hash == rhs.hash
    }
    
    static var defaultValue: [Schedule] { [] }
    
    private let hash: Int
    private let query: QueryInterfaceRequest<Schedule>
    var ordering: Ordering
    
    /// Selects every transaction in the database
    init(order: Ordering = .none){
        query = Schedule.all()
        hash = genHash([1234567])
        self.ordering = order
    }
    
    func fetchValue(_ db: Database) throws -> [Schedule] {
        switch ordering {
        case .none: return try query.fetchAll(db)
        }
    }
    
    enum Ordering {
        case none
    }
}
