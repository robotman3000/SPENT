//
//  TransactionFilter.swift
//  SPENT
//
//  Created by Eric Nims on 7/3/21.
//

import Foundation
import GRDB

struct TransactionFilter {
    let includeTree: Bool
    let showInTree: Bool
    let bucket: Bucket
    let textFilter: String

    func getMatches(_ db: Database) throws -> [TransactionData] {
        let bkts = CommonTableExpression(
            recursive: true,
            named: "bkts",
            sql: """
                SELECT id FROM Buckets e WHERE e.id = \(bucket.id ?? -1)
            
                \(includeTree ? """
                    UNION ALL
                    
                    SELECT e.id FROM Buckets e
                    JOIN bkts c ON c.id = e.Parent
                    """ : "")
            """
        )
        
        let balance = CommonTableExpression(
            named: "transactionBalance",
            sql: "SELECT * FROM transactionBalance"
        )
        
        let balanceAssociation = Transaction.association(
            to: balance,
            on: { transactions, balance in
                // If ancestorID is nil that means the bucket is the ancestor
                transactions[Column("id")] == balance[Column("tid")] && bucket.ancestorID ?? bucket.id! == balance[Column("aid")]
            })
        
        let query = Transaction.filter(sql: """
            ((
                (
                    SourceBucket IN (SELECT * FROM bkts) OR DestBucket IN (SELECT * FROM bkts)
                ) AND (
                    \"Group\" IS NULL
                )
            ) OR (
                (
                    "Group" IN (
                        SELECT "Group" FROM Transactions
                        WHERE
                            (
                                SourceBucket IN (SELECT * FROM bkts) OR DestBucket IN (SELECT * FROM bkts)
                            ) AND (
                                \"Group\" IS NOT NULL
                            )
                        GROUP BY "Group"
                    )
                ) AND (
                    SourceBucket IS NULL AND DestBucket IS NULL
                )
            )) \(!showInTree ? """
                AND Transactions.id NOT IN
                (SELECT t.id AS tid
                FROM Transactions t
                LEFT JOIN Buckets b1 ON SourceBucket = b1.id
                LEFT JOIN Buckets b2 ON DestBucket = b2.id
                WHERE (IFNULL(b1.V_Ancestor, -1) == IFNULL(b2.V_Ancestor, -1) AND b1.V_Ancestor IS NOT NULL) OR V_Type IN (4, 5))
            """ : "")
            
            """).order(sql: "IFNULL(tdate, TransDate)")
            
            .including(all: Transaction.tags.forKey("tags"))
            .including(optional: Transaction.source.forKey("source"))
            .including(optional: Transaction.destination.forKey("destination"))
            .including(all: Transaction.splitMembers.forKey("splitMembers"))
            .with(bkts)
            .including(optional: balanceAssociation.forKey("transactionBalance"))
            
        
        var result = try TransactionData.fetchAll(db, query)
        //let data = try Row.fetchAll(db, query)
        //print(data[0].debugDescription)
        //var result: [TransactionData] = []
        if !textFilter.isEmpty {
            result = result.filter({ item in
                item.transaction.memo.contains(textFilter)
            })
        }
        
        for index in result.indices {
            result[index].preCalcValues(contextBucket: bucket)
        }
        
        return result
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

