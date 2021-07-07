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
    
    func generateQuery(_ db: Database) throws -> QueryInterfaceRequest<Transaction> {
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

        return Transaction.filter(sql: "SourceBucket in (\(bucketStr)) OR DestBucket in (\(bucketStr))")
    }
}
