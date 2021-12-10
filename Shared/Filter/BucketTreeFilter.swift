//
//  BucketTreeFilter.swift
//  macOS
//
//  Created by Eric Nims on 11/16/21.
//

import Foundation
import GRDB
import Combine
import SwiftUI

struct BucketTreeFilter: Queryable, DatabaseFilter {
    typealias Request = BucketRequest

    static var defaultValue: [BucketTreeNode] { [] }
    
    // TODO: Implement support for these filter arguments
    var nameLike: String?
    var order: Ordering = .none
    
    func fetchValue(_ db: Database) throws -> [BucketTreeNode] {
        // Select all the accounts first
        var tree: [BucketTreeNode] = []
        let accounts = try Bucket.selectID().filter(Bucket.Columns.ancestor == nil).order(Bucket.Columns.name).fetchAll(db)
        
        // For each account get its buckets
        for accountID in accounts {
            let buckets = try Bucket.selectID().filter(Bucket.Columns.ancestor == accountID).order(Bucket.Columns.name).fetchAll(db)
            
            // And create a node for it
            tree.append(BucketTreeNode(id: accountID, isAccount: true, children: buckets.isEmpty ? nil : buckets.map({id in BucketTreeNode(id: id, isAccount: false, children: nil)})))
        }
        
        return tree
    }
    
    static func publisher(_ withReader: DatabaseReader, forID: Int64) -> AnyPublisher<Request.Value, Error> {
        let request = BucketRequest(forID: forID, includeAggregate: false)
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
    
    enum FilterMode {
        case accountOnly
        case bucketOnly
        case all
    }
}
