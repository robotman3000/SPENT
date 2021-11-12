//
//  AttachmentRequest.swift
//  macOS
//
//  Created by Eric Nims on 10/7/21.
//

import GRDB

/// Make `PlayerRequest` able to be used with the `@Query` property wrapper.
struct AttachmentRequest: DatabaseRequest {
    var forID: Int64
    
    func requestValue(_ db: Database) throws -> Attachment {
        do {
            if let attachment = try Attachment.fetchOne(db, id: forID) {
                return attachment
            }
        }
        throw RequestFetchError()
    }
}

struct AttachmentQuery: Queryable {
    static var defaultValue: [Attachment] = []
    
    func fetchValue(_ db: Database) throws -> [Attachment] {
        return try Attachment.fetchAll(db)
    }
}
