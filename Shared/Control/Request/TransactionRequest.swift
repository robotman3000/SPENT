//
//  TransactionRequest.swift
//  SPENT
//
//  Created by Eric Nims on 5/12/21.
//


import GRDB
import Foundation

/// A player request defines how to feed the player list
//struct TransactionRequest {
//    enum Ordering {
//        case byScore
//        case byName
//    }
//
//    var ordering: Ordering
//}

/// Make `PlayerRequest` able to be used with the `@Query` property wrapper.
struct TransactionRequest: Queryable {
    static func == (lhs: TransactionRequest, rhs: TransactionRequest) -> Bool {
        return lhs.hash == rhs.hash
    }
    
    static var defaultValue: [Transaction] { [] }
    
    private let hash: Int
    private let query: QueryInterfaceRequest<Transaction>?
    var ordering: Ordering = .none
    
    /// Selects every transaction in the database if includeAll is true
    init(_ includeAll: Bool = false){
        if includeAll {
            query = Transaction.all()
        } else {
            query = nil
        }
        hash = genHash([1234567, includeAll])
    }
    
    init(_ groupID: UUID){
        query = Transaction.filter(Transaction.Columns.group == groupID.uuidString)
        hash = genHash([groupID])
    }
    
    init(_ bucket: Bucket){
        //print("bucket iinit")
        query = Transaction.filter(sql: "SourceBucket == ? OR DestBucket == ?", arguments: [bucket.id, bucket.id])
        hash = genHash([bucket])
    }
    
    init(_ bucket: Bucket, query: QueryInterfaceRequest<Transaction>){
        //print("bucket iinit")
        self.query = query.filter(sql: "SourceBucket == ? OR DestBucket == ?", arguments: [bucket.id, bucket.id])
        hash = genHash([bucket])
    }
    
    init(_ tag: Tag){
        //print("tag init")
        //query = Transaction.sql(sql: "SELECT * FROM () as a", arguments: [tag.id])
        query = Transaction.filter(sql: "id in (SELECT TransactionID from TransactionTags WHERE TagID == ?)", arguments: [tag.id])
        //print(query.sqlExpression)
        hash = genHash([tag])
    }
    
    func fetchValue(_ db: Database) throws -> [Transaction] {
//        switch ordering {
//        case .byScore: return try Transaction.all().orderedByScore().fetchAll(db)
//        case .byName: return try Player.all().orderedByName().fetchAll(db)
//        }
        print("Running DB Query")
        if query != nil {
            let result = try query!.fetchAll(db)
            print("Returning DB Query")
            //print(result)
            return result
        }
        print("Returning empty result")
        return []
    }

    enum Ordering {
        case none
        //case byName
    }
}
