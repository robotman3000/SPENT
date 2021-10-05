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
    var onlyFavorite: Bool
    
    /// Selects every transaction in the database
    init(order: Ordering = .byTree, onlyFavorite: Bool = false){
        query = Bucket.all()
        hash = genHash([1234567, order])
        self.ordering = order
        self.onlyFavorite = onlyFavorite
    }
    
    init(order: Ordering = .byTree, rootNode: Bucket, onlyFavorite: Bool = false){
        query = Bucket.all()
        hash = genHash([order, rootNode])
        self.ordering = order
        self.onlyFavorite = onlyFavorite
    }
    
    func fetchValue(_ db: Database) throws -> [Bucket] {
        var q = query
        if onlyFavorite {
            q = q.filter(Bucket.Columns.favorite == true)
        }
        
        switch ordering {
        case .byTree: return try q.orderByTree().fetchAll(db)
        case .none: return try q.fetchAll(db)
        }
    }
    
    enum Ordering {
        case none
        case byTree
        //case byName
    }
}


