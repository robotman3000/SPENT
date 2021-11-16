//
//  TemplateFilter.swift
//  macOS
//
//  Created by Eric Nims on 11/16/21.
//

import Combine
import GRDB
import SwiftUI

struct TemplateFilter: Queryable, DatabaseFilter {
    typealias Request = TemplateRequest

    static var defaultValue: [Int64] { [] }
    
    func fetchValue(_ db: Database) throws -> [Int64] {
        let query = DBTransactionTemplate.selectID()
    
        return try query.fetchAll(db)
    }
    
    static func publisher(_ withReader: DatabaseReader, forID: Int64) -> AnyPublisher<DBTransactionTemplate, Error> {
        let request = TemplateRequest(forID: forID)
        let publisher = ValueObservation
            .tracking(request.requestValue)
            .publisher(
                in: withReader, scheduling: .async(onQueue: DispatchQueue.init(label: "UI Database Queue"))).eraseToAnyPublisher()
        return publisher
    }
}
