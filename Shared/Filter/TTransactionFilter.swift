//
//  TTransactionFilter.swift
//  macOS
//
//  Created by Eric Nims on 10/19/21.
//

import Foundation
import GRDB
import Combine

struct TTransactionFilter: Queryable, DatabaseFilter {
    typealias Request = TTransactionRequest
    
    static var defaultValue: [Int64] { [] }
    
    let forBucket: Int64
    
    var includeBucketTree: Bool = false
    var showAllocations: Bool = false
    var memoLike: String? = nil

    func fetchValue(_ db: Database) throws -> [Int64] {
        let bkts = CommonTableExpression(
            recursive: true,
            named: "bkts",
            sql: """
                SELECT id FROM Buckets e WHERE e.id = \(forBucket)
            \(includeBucketTree ? """
                UNION ALL
                SELECT e.id FROM Buckets e
                JOIN bkts c ON c.id = e.Parent
            """ : "")
            """
        )
        
        let splits = CommonTableExpression(
            recursive: false,
            named: "splits",
            sql: """
                SELECT DISTINCT "Group" FROM Transactions WHERE (SourceBucket IN (SELECT id FROM bkts) OR DestBucket IN (SELECT id FROM bkts)) AND V_Type == 4
            """
        )
        
        var query = Transaction.selectID().filter(sql: """
                (("Group" IS NULL AND (SourceBucket IN (SELECT id FROM bkts) OR DestBucket IN (SELECT id FROM bkts))) OR ("Group" IN (SELECT * FROM splits) AND V_Type == 5))
            \(!showAllocations ? """
                AND Transactions.id NOT IN
                (SELECT t.id AS tid
                FROM Transactions t
                LEFT JOIN Buckets b1 ON SourceBucket = b1.id
                LEFT JOIN Buckets b2 ON DestBucket = b2.id
                WHERE (IFNULL(b1.V_Ancestor, -1) == IFNULL(b2.V_Ancestor, -1) AND b1.V_Ancestor IS NOT NULL) OR V_Type IN (4, 5))
            """ : "")
            """)
        
        if let nameFilter = memoLike {
            query = query.filter(Transaction.Columns.memo.like("%\(nameFilter)%"))
        }
        
        return try query.with(bkts).with(splits).fetchAll(db)
    }
    
    static func publisher(_ withReader: DatabaseReader, forID: Int64) -> AnyPublisher<TransactionModel, Error> {
        let request = TTransactionRequest(forID: forID)
        let publisher = ValueObservation
            .tracking(request.requestValue)
            .publisher(
                in: withReader, scheduling: .async(onQueue: DispatchQueue.init(label: "UI Database Queue"))).eraseToAnyPublisher()
        return publisher
    }
    
    enum Ordering: Int, Identifiable, CaseIterable, Stringable {
        case byDate
        case byPayee
        case byMemo
        case bySource
        case byDestination
        case byStatus
        case byAmount
        
        var id: Int { self.rawValue }
        
        func getStringName() -> String {
            switch self {
            case .byDate: return "Date"
            case .byPayee: return "Payee"
            case .byMemo: return "Memo"
            case .bySource: return "Source"
            case .byDestination: return "Destination"
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

