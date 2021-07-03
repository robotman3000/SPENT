//
//  File.swift
//  SPENT
//
//  Created by Eric Nims on 7/3/21.
//

import Foundation
import GRDB

struct TransactionModelRequest: Queryable {
    static func == (lhs: TransactionModelRequest, rhs: TransactionModelRequest) -> Bool {
        return lhs.hash == rhs.hash
    }
    
    static var defaultValue: [TransactionData] { [] }
    
    private let hash: Int
    
    /// This query is used to filter and sort the transactions after being selected by bucket
    private let filter: TransactionFilter
    //var ordering: Ordering = .none
    
    /// Selects every transaction in the database if includeAll is true
    init(_ withFilter: TransactionFilter){
        self.filter = withFilter
        hash = genHash([1234567, withFilter.bucket, withFilter.includeTree])
    }
//
//    init(_ groupID: UUID){
//        query = Transaction.filter(Transaction.Columns.group == groupID.uuidString)
//        hash = genHash([groupID])
//    }
//
//    init(_ bucket: Bucket){
//        //print("bucket iinit")
//        query = Transaction.filter(sql: "SourceBucket == ? OR DestBucket == ?", arguments: [bucket.id, bucket.id])
//        hash = genHash([bucket])
//    }
//
//    init(_ bucket: Bucket, query: QueryInterfaceRequest<Transaction>){
//        //print("bucket iinit")
//        self.query = query.filter(sql: "SourceBucket == ? OR DestBucket == ?", arguments: [bucket.id, bucket.id])
//        hash = genHash([bucket])
//    }
    
    func fetchValue(_ db: Database) throws -> [TransactionData] {
        let transactionQuery = filter.generateQuery()
            .including(all: Transaction.tags.forKey("tags"))
            .including(optional: Transaction.source.forKey("source"))
            .including(optional: Transaction.destination.forKey("destination"))
        
        //let result = try Row.fetchAll(db, transactionQuery)
        //print(result[0].debugDescription)
        let result = try TransactionData.fetchAll(db, transactionQuery)
        return result
        //print(result[0])
        //return []
    }

    enum Ordering {
        case none
        //case byName
    }
}
