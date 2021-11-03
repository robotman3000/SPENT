//
//  TagFilter.swift
//  macOS
//
//  Created by Eric Nims on 10/16/21.
//

import Combine
import GRDB
import SwiftUI

struct TagFilter: Queryable, DatabaseFilter {
    typealias Request = TagRequest

    static var defaultValue: [Int64] { [] }
    var onlyFavorite: Bool = false
    var nameLike: String?
    var order: Ordering = .none
    
    func fetchValue(_ db: Database) throws -> [Int64] {
        var query = Tag.selectID()
        if onlyFavorite {
            query = query.filter(Tag.Columns.favorite == true)
        }
    
        if let nameFilter = nameLike {
            query = query.filter(Tag.Columns.name.like("%\(nameFilter)%"))
        }
        
        switch order {
        case .byName: query = query.order(Tag.Columns.name)
        case .none: query = query.orderByPrimaryKey()
        }
        return try query.fetchAll(db)
    }
    
    static func publisher(_ withReader: DatabaseReader, forID: Int64) -> AnyPublisher<Tag, Error> {
        let request = TagRequest(forID: forID)
        let publisher = ValueObservation
            .tracking(request.requestValue)
            .publisher(
                in: withReader, scheduling: .async(onQueue: DispatchQueue.init(label: "UI Database Queue"))).eraseToAnyPublisher()
        return publisher
    }
    
    enum Ordering {
        case none
        case byName
    }
}
