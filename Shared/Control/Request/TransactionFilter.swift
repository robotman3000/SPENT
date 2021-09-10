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
        var buckets = [bucket]
        if includeTree {
            let result = try bucket.tree.fetchAll(db)
            buckets.append(contentsOf: result)
        }
        
        var bucketIDs: [Int64] = []
        for bucket in buckets {
            if bucket.id != nil {
                bucketIDs.append(bucket.id!)
            }
        }
        let bucketStr: String = bucketIDs.map({ val in return "\(val)" }).joined(separator: ", ")

        let query = Transaction.filter(sql: """
            
            (
                (
                    SourceBucket IN (\(bucketStr)) OR DestBucket IN (\(bucketStr))
                ) AND (
                    \"Group\" IS NULL
                )
            ) OR (
                (
                    "Group" IN (
                        SELECT "Group" FROM Transactions
                        WHERE
                            (
                                SourceBucket IN (\(bucketStr)) OR DestBucket IN (\(bucketStr))
                            ) AND (
                                \"Group\" IS NOT NULL
                            )
                        GROUP BY "Group"
                    )
                ) AND (
                    SourceBucket IS NULL AND DestBucket IS NULL
                )
            )
            
            """).including(all: Transaction.tags.forKey("tags"))
            .including(optional: Transaction.source.forKey("source"))
            .including(optional: Transaction.destination.forKey("destination"))
            .including(all: Transaction.splitMembers.forKey("splitMembers"))
        
        var result = try TransactionData.fetchAll(db, query)
        
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

