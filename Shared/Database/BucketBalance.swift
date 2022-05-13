//
//  BucketBalance.swift
//  macOS
//
//  Created by Eric Nims on 5/13/22.
//

import Foundation
import GRDB

struct BucketBalance: Decodable, FetchableRecord, TableRecord {
    let bucketId: Int64
    let accountId: Int64
    let posted: Int
    let available: Int
    
    static let account = hasOne(Account.self, using: ForeignKey(["id"], to: ["AccountID"]))
    static let bucket = hasOne(Bucket.self, using: ForeignKey(["id"], to: ["BucketID"]))
}

extension DerivableRequest where RowDecoder == BucketBalance {
    func filter(account: Account) -> Self {
        filter(Column("AccountID") == account.id)
    }
    
    func filter(bucket: Bucket) -> Self {
        filter(Column("BucketID") == bucket.id)
    }
}

