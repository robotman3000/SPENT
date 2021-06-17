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
    
    /// Selects every transaction in the database
    init(){
        query = Tag.all()
        hash = genHash([1234567])
    }
    
    func fetchValue(_ db: Database) throws -> [Tag] {
//        switch ordering {
//        case .byScore: return try Transaction.all().orderedByScore().fetchAll(db)
//        case .byName: return try Player.all().orderedByName().fetchAll(db)
//        }
        return try query.fetchAll(db)
    }
}
