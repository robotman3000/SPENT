//
//  ScheduleFilter.swift
//  macOS
//
//  Created by Eric Nims on 10/28/21.
//

import GRDB
import Combine
import SwiftUI

struct ScheduleFilter: Queryable, DatabaseFilter {
    typealias Request = ScheduleRequest

    static var defaultValue: [Int64] { [] }
    var onlyFavorite: Bool = false
    
    func fetchValue(_ db: Database) throws -> [Int64] {
        var query = Tag.selectID()
        if onlyFavorite {
            query = query.filter(Tag.Columns.favorite == true)
        }

        return try query.fetchAll(db)
    }
    
    static func publisher(_ withReader: DatabaseReader, forID: Int64) -> AnyPublisher<Schedule, Error> {
        let request = ScheduleRequest(forID: forID)
        let publisher = ValueObservation
            .tracking(request.requestValue)
            .publisher(
                in: withReader, scheduling: .async(onQueue: DispatchQueue.init(label: "UI Database Queue"))).eraseToAnyPublisher()
        return publisher
    }
}
