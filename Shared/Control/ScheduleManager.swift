//
//  ScheduleManager.swift
//  SPENT
//
//  Created by Eric Nims on 7/21/21.
//

import Foundation
import GRDB

struct ScheduleRenderer {
    
    static func render(appDB: AppDatabase, schedule: Schedule, from: Date, to: Date) -> [Transaction]{
        print("Rendering schedule \(schedule.name) for date range \(from.transactionFormat) - \(to.transactionFormat)")
        return []
    }
}
