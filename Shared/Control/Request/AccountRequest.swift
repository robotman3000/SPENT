//
//  AccountRequest.swift
//  macOS
//
//  Created by Eric Nims on 9/2/21.
//

import Foundation
import GRDB

/// Make `AccountRequest` able to be used with the `@Query` property wrapper.
struct AccountRequest: Queryable {
    static func == (lhs: AccountRequest, rhs: AccountRequest) -> Bool {
        return lhs.hash == rhs.hash
    }
    
    static var defaultValue: [Bucket] { [] }
    
    private let hash: Int
    private let query: QueryInterfaceRequest<Bucket>
    
    /// Selects every transaction in the database
    init(){
        query = Bucket.all().filterAccounts()
        hash = genHash([1234567])
    }
    
    func fetchValue(_ db: Database) throws -> [Bucket] {
        try query.fetchAll(db)
    }
}

