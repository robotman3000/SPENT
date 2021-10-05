//
//  TransactionRequest.swift
//  SPENT
//
//  Created by Eric Nims on 5/12/21.
//


import GRDB

/// Make `PlayerRequest` able to be used with the `@Query` property wrapper.
struct TagRequest: Queryable {
    static func == (lhs: TagRequest, rhs: TagRequest) -> Bool {
        return lhs.hash == rhs.hash
    }
    
    static var defaultValue: [Tag] { [] }
    
    private let hash: Int
    private let query: QueryInterfaceRequest<Tag>
    var ordering: Ordering
    var onlyFavorite: Bool
    
    /// Selects every transaction in the database
    init(order: Ordering = .none, onlyFavorite: Bool = false){
        query = Tag.all()
        hash = genHash([1234567])
        self.ordering = order
        self.onlyFavorite = onlyFavorite
    }
    
    init(_ transaction: Transaction, order: Ordering = .none, onlyFavorite: Bool = false){
        query = transaction.tags
        hash = genHash([1234567, transaction])
        self.ordering = order
        self.onlyFavorite = onlyFavorite
    }
    
    func fetchValue(_ db: Database) throws -> [Tag] {
        var q = query
        if onlyFavorite {
            q = q.filter(Tag.Columns.favorite == true)
        }
        
        switch ordering {
        case .none: return try q.fetchAll(db)
        }
    }
    
    enum Ordering {
        case none
    }
}
