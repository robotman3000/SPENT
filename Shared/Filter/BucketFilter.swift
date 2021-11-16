//
//  BucketFilter.swift
//  SPENT
//
//  Created by Eric Nims on 10/16/21.
//

import Foundation
import GRDB
import Combine
import SwiftUI

struct BucketFilter: Queryable, DatabaseFilter {
    typealias Request = BucketRequest

    static var defaultValue: [Int64] { [] }
    
    var onlyFavorite: Bool = false
    var nameLike: String?
    var order: Ordering = .none
    var mode: FilterMode = .all
    
    func fetchValue(_ db: Database) throws -> [Int64] {
        var query = Bucket.selectID()
        switch mode {
        case .accountOnly:
            query = query.filter(Bucket.Columns.ancestor != nil)
        case .bucketOnly:
            query = query.filter(Bucket.Columns.ancestor == nil)
        case .all:
            print("Happy Compiler")
        }
        
        if onlyFavorite {
            query = query.filter(Bucket.Columns.favorite == true)
        }
    
        if let nameFilter = nameLike {
            query = query.filter(Bucket.Columns.name.like("%\(nameFilter)%"))
        }
        
        switch order {
        case .byName: query = query.order(Bucket.Columns.name)
        case .none: query = query.orderByPrimaryKey()
        }
        let result = try query.fetchAll(db)
        //print("filter result")
        return result
    }
    
    static func publisher(_ withReader: DatabaseReader, forID: Int64) -> AnyPublisher<Request.Value, Error> {
        //print("filter make pblisher")
        let request = BucketRequest(forID: forID, includeAggregate: true)
        let publisher = ValueObservation
            .tracking(request.requestValue)
            .publisher(
                in: withReader, scheduling: .async(onQueue: DispatchQueue.init(label: "UI Database Queue"))).eraseToAnyPublisher()
        //print("filter return pblisher")
        return publisher
    }

    enum Ordering {
        case none
        case byName
    }
    
    enum FilterMode {
        case accountOnly
        case bucketOnly
        case all
    }
}
