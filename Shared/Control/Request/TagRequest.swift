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
    
    /// Selects every transaction in the database
    init(order: Ordering = .none){
        query = Tag.all()
        hash = genHash([1234567])
        self.ordering = order
    }
    
    func fetchValue(_ db: Database) throws -> [Tag] {
        switch ordering {
        case .none: return try query.fetchAll(db)
        }
    }
    
    enum Ordering {
        case none
    }
}
