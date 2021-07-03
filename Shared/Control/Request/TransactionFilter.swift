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
    
    func generateQuery() -> QueryInterfaceRequest<Transaction> {
        return Transaction.filter(sql: "SourceBucket == ? OR DestBucket == ?", arguments: [bucket.id, bucket.id])
    }
}
