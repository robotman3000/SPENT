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
    var onlyFavorite: Bool
    
    /// Selects every transaction in the database
    init(order: Ordering = .none, onlyFavorite: Bool = false){
        query = Schedule.all()
        hash = genHash([1234567])
        self.ordering = order
        self.onlyFavorite = onlyFavorite
    }
    
    func fetchValue(_ db: Database) throws -> [Schedule] {
        var q = query
        if onlyFavorite {
            q = q.filter(Schedule.Columns.favorite == true)
        }
        
        switch ordering {
        case .none: return try q.fetchAll(db)
        }
    }
    
    enum Ordering {
        case none
    }
}
