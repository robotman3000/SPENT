//
//  ScheduleRequest.swift
//  SPENT
//
//  Created by Eric Nims on 6/19/21.
//

import Foundation
import GRDB

/// Make `ScheduleREquest` able to be used with the `@Query` property wrapper.
struct ScheduleRequest: DatabaseRequest {
    var forID: Int64
    
    func requestValue(_ db: Database) throws -> Schedule {
        do {
            if let schedule = try Schedule.fetchOne(db, id: forID) {
                return schedule
            }
        }
        throw RequestFetchError("requestValue failed for ScheduleRequest")
    }
}
