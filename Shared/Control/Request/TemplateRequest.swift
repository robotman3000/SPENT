//
//  TemplateRequest.swift
//  macOS
//
//  Created by Eric Nims on 10/5/21.
//

import GRDB

/// Make `TemplateRequest` able to be used with the `@Query` property wrapper.
struct TemplateRequest: Queryable {
    static func == (lhs: TemplateRequest, rhs: TemplateRequest) -> Bool {
        return lhs.hash == rhs.hash
    }
    
    static var defaultValue: [DBTransactionTemplate] { [] }
    
    private let hash: Int
    private let query: QueryInterfaceRequest<DBTransactionTemplate>
    
    /// Selects every transaction in the database
    init(){
        query = DBTransactionTemplate.all()
        hash = genHash([1234567])
    }
    
    func fetchValue(_ db: Database) throws -> [DBTransactionTemplate] {
        return try query.fetchAll(db)
    }
}
