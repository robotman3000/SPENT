//
//  SingleBucketRequest.swift
//  macOS
//
//  Created by Eric Nims on 9/2/21.
//

import Foundation
import GRDB

/// Make `SingleBucketRequest` able to be used with the `@Query` property wrapper.
struct SingleBucketRequest: Queryable {
    static func == (lhs: SingleBucketRequest, rhs: SingleBucketRequest) -> Bool {
        return lhs.hash == rhs.hash
    }
    
    static var defaultValue: Bucket?
    
    private let hash: Int
    private let query: QueryInterfaceRequest<Bucket>
    
    /// Selects every transaction in the database
    init(id: Int64){
        query = Bucket.filter(id: id)
        hash = genHash([1234567, id])
    }

    func fetchValue(_ db: Database) throws -> Bucket? {
        try query.fetchOne(db)
    }
}
