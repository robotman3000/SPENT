//
//  TransactionRequest.swift
//  SPENT
//
//  Created by Eric Nims on 5/12/21.
//


import GRDB

/// Make `BucketRequest` able to be used with the `@Query` property wrapper.
struct BucketRequest: Queryable {
    static func == (lhs: BucketRequest, rhs: BucketRequest) -> Bool {
        return lhs.hash == rhs.hash
    }
    
    static var defaultValue: [Bucket] { [] }
    
    private let hash: Int
    private let query: QueryInterfaceRequest<Bucket>
    var ordering: Ordering
    
    /// Selects every transaction in the database
    init(order: Ordering = .byTree){
        query = Bucket.all()
        hash = genHash([1234567])
        self.ordering = order
    }
    
    func fetchValue(_ db: Database) throws -> [Bucket] {
        switch ordering {
        case .byTree: return try query.orderByTree().fetchAll(db)
        case .none: return try query.fetchAll(db)
        }
    }
    
    enum Ordering {
        case none
        case byTree
        //case byName
    }
}


