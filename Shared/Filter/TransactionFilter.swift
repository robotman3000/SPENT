//
//  TTransactionFilter.swift
//  macOS
//
//  Created by Eric Nims on 10/19/21.
//

import Foundation
import GRDB
import Combine

struct TransactionFilter: Queryable, DatabaseFilter {
    typealias Request = TransactionRequest
    
    static var defaultValue: [Int64] { [] }
    
    let forBucket: Int64?
    
    var includeBucketTree: Bool = false
    var showAllocations: Bool = false
    var memoLike: String? = nil
    var ordering: Ordering = .byDate
    var direction: OrderDirection = .ascending

    func fetchValue(_ db: Database) throws -> [Int64] {
        var bucketQuery = "SELECT id FROM Buckets"
        
        if let bid = forBucket {
            bucketQuery = """
                SELECT id FROM Buckets e WHERE e.id = \(bid)
            \(includeBucketTree ? """
                UNION ALL
                SELECT e.id FROM Buckets e
                JOIN bkts c ON c.id = e.Parent
            """ : "")
            """
        }
//        var memoFilter = ""
//        if let nameFilter = memoLike {
//            memoFilter = " AND Memo LIKE \"\(nameFilter)\""
//        }
//        \(!memoFilter.isEmpty ? memoFilter : "")
        
        let rows = try Row.fetchAll(db, sql: """
            WITH
            "bkts" AS (\(bucketQuery))
            SELECT id FROM allTransactions WHERE Bucket IN (SELECT id FROM bkts) \(!showAllocations ? " AND isAllocation == false " : "")
            ORDER BY "\(ordering.getStringName())\" \(direction == .ascending ? "ASC" : "DESC")
            """)
        let ids: [Int64] = rows.map({ $0[0] })
        
        return ids
    }
    
    static func publisher(_ withReader: DatabaseReader, forID: Int64) -> AnyPublisher<TransactionModel, Error> {
        let request = TransactionRequest(forID: forID)
        return publisher(withReader, forRequest: request)
    }
    
    static func publisher(_ withReader: DatabaseReader, forRequest: TransactionRequest) -> AnyPublisher<TransactionModel, Error> {
        let publisher = ValueObservation
            .tracking(forRequest.requestValue)
            .publisher(
                in: withReader, scheduling: .async(onQueue: DispatchQueue.init(label: "UI Database Queue"))).eraseToAnyPublisher()
        return publisher
    }
    
    static func publisher2(_ withReader: DatabaseReader, forRequest: TransactionRequest) -> AnyPublisher<TransactionModel, Error> {
        let publisher = ValueObservation
            .tracking(forRequest.requestValue)
            .publisher(
                in: withReader, scheduling: .async(onQueue: DispatchQueue.init(label: "UI Database Queue"))).eraseToAnyPublisher()
        return publisher
    }
    
    enum Ordering: Int, Identifiable, CaseIterable, Stringable {
        case byDate
        case byPayee
        case byMemo
        case byBucket
        case byAccount
        case byStatus
        case byAmount
        
        var id: Int { self.rawValue }
        
        func getStringName() -> String {
            switch self {
            case .byDate: return "Date"
            case .byPayee: return "Payee"
            case .byMemo: return "Memo"
            case .byBucket: return "Bucket"
            case .byAccount: return "Account"
            case .byStatus: return "Status"
            case .byAmount: return "Amount"
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

