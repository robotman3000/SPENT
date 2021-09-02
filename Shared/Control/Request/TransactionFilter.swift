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
    let bucket: Bucket
    let order: TransactionFilter.Ordering
    let orderDirection: TransactionFilter.OrderDirection

    func getMatchedIDs(_ db: Database) throws -> [TransactionData] {
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

        var query = Transaction.filter(sql: """
            
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
        
        
                switch(order){
                case .byDate: query = query.orderedByDate()
                case .byPayee: query = query.orderedByPayee()
                case .byMemo: query = query.orderedByMemo()
                case .bySource: query = query.orderedBySource()
                case .byDestination: query = query.orderedByDestination()
                case .byStatus: query = query.orderedByStatus()
                case .byAmount: 1 + 1
                }
//
                //let result = try Row.fetchAll(db, transactionQuery)
                //print(result[0].debugDescription)
        
        var result = try TransactionData.fetchAll(db, query)
        
        if orderDirection == .ascending && order != .byAmount {
            result = result.reversed()
        }

        if order == .byAmount {
            // We sort this in code rather than SQL because all amounts are stored as positive integers
            if orderDirection == .ascending {
                result.sort {
                    if $0.transaction.type == .Transfer && $1.transaction.type == .Transfer {
                        return $0.transaction.amountNegative < $1.transaction.amountNegative
                    }
                    if $0.transaction.type == .Transfer {
                        return false
                    }
                    if $1.transaction.type == .Transfer {
                        return true
                    }

                    return $0.transaction.amountNegative < $1.transaction.amountNegative
                }
            } else {
                result.sort {
                    if $0.transaction.type == .Transfer && $1.transaction.type == .Transfer {
                        return $0.transaction.amountNegative > $1.transaction.amountNegative
                    }
                    if $0.transaction.type == .Transfer {
                        return true
                    }
                    if $1.transaction.type == .Transfer {
                        return false
                    }

                    return $0.transaction.amountNegative > $1.transaction.amountNegative
                }
            }
        }
        
        return result
        //return result.map({ $0.id ?? -1 })
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

