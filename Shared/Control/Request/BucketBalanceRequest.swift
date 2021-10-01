//
//  BucketBalanceRequest.swift
//  SPENT
//
//  Created by Eric Nims on 6/21/21.
//

import GRDB

/// Make `PlayerRequest` able to be used with the `@Query` property wrapper.
struct BucketBalanceRequest: Queryable {
    static func == (lhs: BucketBalanceRequest, rhs: BucketBalanceRequest) -> Bool {
        return lhs.hash == rhs.hash
    }
    
    static var defaultValue: BucketBalance { BucketBalance(bucketID: -1, available: 0, posted: 0) }
    private let bucket: Bucket?
    private let hash: Int
    
    /// Selects every transaction in the database
    init(_ bucket: Bucket?){
        self.bucket = bucket
        hash = genHash([1234567, bucket])
    }
    
    func fetchValue(_ db: Database) throws -> BucketBalance {
        if let bk = bucket {
            do {
                var tree = try bk.tree.fetchAll(db)
                tree.append(bk)
                
                var bucketIDs: [Int64] = []
                for bucket in tree {
                    if bucket.id != nil {
                        bucketIDs.append(bucket.id!)
                    }
                }
                let bucketStr: String = bucketIDs.map({ "\($0)" }).joined(separator: ", ")
                
                let balance = try BucketBalance.fetchOne(db, sql: """
                    SELECT * FROM \(BucketBalance.databaseTableName) a LEFT JOIN (SELECT SUM(available) AS "availableTree", SUM(posted) AS "postedTree" FROM \(BucketBalance.databaseTableName) b WHERE b.bid IN (\(bucketStr))) WHERE a.bid == \(bk.id!)
                """)
                if let b = balance {
                    return b
                }
                return BucketBalance(bucketID: -1, available: 0, posted: 0)
            } catch {
                print("Error while calculating balance for bucket")
                throw error
            }
        } else {
            return BucketBalanceRequest.defaultValue
        }
    }
}
