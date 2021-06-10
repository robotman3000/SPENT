//
//  TransactionRequest.swift
//  SPENT
//
//  Created by Eric Nims on 5/12/21.
//


import GRDB

/// A player request defines how to feed the player list
//struct TransactionRequest {
//    enum Ordering {
//        case byScore
//        case byName
//    }
//
//    var ordering: Ordering
//}

/// Make `PlayerRequest` able to be used with the `@Query` property wrapper.
struct BucketRequest: Queryable {
    static func == (lhs: BucketRequest, rhs: BucketRequest) -> Bool {
        return lhs.hash == rhs.hash
    }
    
    static var defaultValue: [Bucket] { [] }
    
    private let hash: Int
    private let query: QueryInterfaceRequest<Bucket>
    
    /// Selects every transaction in the database
    init(){
        query = Bucket.all()
        hash = genHash([1234567])
    }
    
    func fetchValue(_ db: Database) throws -> [Bucket] {
//        switch ordering {
//        case .byScore: return try Transaction.all().orderedByScore().fetchAll(db)
//        case .byName: return try Player.all().orderedByName().fetchAll(db)
//        }
        return try query.fetchAll(db)
    }
}


