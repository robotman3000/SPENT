//
//  TemplateRequest.swift
//  macOS
//
//  Created by Eric Nims on 10/5/21.
//

import GRDB

/// Make `TemplateRequest` able to be used with the `@Query` property wrapper.
struct TemplateRequest: DatabaseRequest {
    var forID: Int64
    
    func requestValue(_ db: Database) throws -> DBTransactionTemplate {
        do {
            if let template = try DBTransactionTemplate.fetchOne(db, id: forID) {
                return template
            }
        }
        throw RequestFetchError()
    }
}
