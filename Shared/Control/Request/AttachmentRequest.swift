//
//  AttachmentRequest.swift
//  macOS
//
//  Created by Eric Nims on 10/7/21.
//

import GRDB

/// Make `PlayerRequest` able to be used with the `@Query` property wrapper.
struct AttachmentRequest: Queryable {
    static func == (lhs: AttachmentRequest, rhs: AttachmentRequest) -> Bool {
        return lhs.hash == rhs.hash
    }
    
    static var defaultValue: [Attachment] { [] }
    
    private let hash: Int
    private let query: QueryInterfaceRequest<Attachment>
    
    init(_ transaction: Transaction){
        query = transaction.attachments
        hash = genHash([1234567, transaction])
    }
    
    func fetchValue(_ db: Database) throws -> [Attachment] {
        return try query.fetchAll(db)
    }
}
