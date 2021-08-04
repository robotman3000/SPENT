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
    
    let order: Ordering
    let orderDirection: OrderDirection
    
    /// Selects every transaction in the database if includeAll is true
    init(_ withFilter: TransactionFilter, order: Ordering, direction: OrderDirection){
        self.filter = withFilter
        self.order = order
        self.orderDirection = direction
        hash = genHash([1234567, withFilter.bucket, withFilter.includeTree, order, direction])
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
        var query = try filter.generateQuery(db)
            .including(all: Transaction.tags.forKey("tags"))
            .including(optional: Transaction.source.forKey("source"))
            .including(optional: Transaction.destination.forKey("destination"))
            .including(all: Transaction.splitMembers.forKey("splitMembers"))
        
        switch(order){
        case .byDate: query = query.orderedByDate()
        case .byPayee: query = query.orderedByPayee()
        case .byMemo: query = query.orderedByMemo()
        case .bySource: query = query.orderedBySource()
        case .byDestination: query = query.orderedByDestination()
        case .byStatus: query = query.orderedByStatus()
        }
        
        //let result = try Row.fetchAll(db, transactionQuery)
        //print(result[0].debugDescription)
        let result = try TransactionData.fetchAll(db, query)
        if orderDirection == .ascending {
            return result.reversed()
        }
        return result
        //print(result[0])
        //return []
    }

    enum Ordering: Int, Identifiable, CaseIterable, Stringable {
        case byDate
        case byPayee
        case byMemo
        case bySource
        case byDestination
        case byStatus
        
        var id: Int { self.rawValue }
        
        func getStringName() -> String {
            switch self {
            case .byDate: return "Date"
            case .byPayee: return "Payee"
            case .byMemo: return "Memo"
            case .bySource: return "Source"
            case .byDestination: return "Destination"
            case .byStatus: return "Status"
            }
        }
    }

    enum OrderDirection: String, Identifiable, CaseIterable, Stringable {
        case ascending
        case descending
        
        var id: String { self.rawValue }
        
        func getStringName() -> String {
            switch self {
            case .ascending: return "Ascending"
            case .descending: return "Descending"
            }
        }
    }
}
