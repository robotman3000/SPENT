//
//  TransactionRequest.swift
//  SPENT
//
//  Created by Eric Nims on 5/12/21.
//


import GRDB

/// Make `PlayerRequest` able to be used with the `@Query` property wrapper.
struct TagRequest: DatabaseRequest {
    var forID: Int64
    
    func requestValue(_ db: Database) throws -> Tag {
        do {
            if let tag = try Tag.fetchOne(db, id: forID) {
                return tag
            }
        }
        throw RequestFetchError("requestValue failed for TagRequest")
    }
}
