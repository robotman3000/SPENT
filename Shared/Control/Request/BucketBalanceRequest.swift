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
    
    static var defaultValue: BucketBalance { BucketBalance(posted: 0, available: 0, postedInTree: 0, availableInTree: 0) }
    private let bucket: Bucket?
    private let hash: Int
    
    /// Selects every transaction in the database
    init(_ bucket: Bucket?){
        self.bucket = bucket
        hash = genHash([1234567, bucket])
    }
    
    func fetchValue(_ db: Database) throws -> BucketBalance {
        if bucket != nil {
            do {
                var pb = 0
                var ptb = 0
                var ab = 0
                var atb = 0
                
                // Posted
                if let row = try Row.fetchOne(db, sql: try getBalanceQuery(buckets: [bucket!], statusTypes: Transaction.StatusTypes.allCases.filter({status in
                    status.rawValue > Transaction.StatusTypes.Submitted.rawValue
                })), arguments: []) {
                    pb = row["Amount"]
                }
            
                // Available
                if let row = try Row.fetchOne(db, sql: try getBalanceQuery(buckets: [bucket!], statusTypes: Transaction.StatusTypes.allCases.filter({status in
                    status.rawValue != Transaction.StatusTypes.Void.rawValue
                })), arguments: []) {
                    ab = row["Amount"]
                }
                
                // Posted Tree
                if let row = try Row.fetchOne(db, sql: try getBalanceQuery(buckets: getTreeAtBucket(bucket!, db: db), statusTypes: Transaction.StatusTypes.allCases.filter({status in
                    status.rawValue > Transaction.StatusTypes.Submitted.rawValue
                })), arguments: []) {
                    ptb = row["Amount"]
                }

                // Available Tree
                if let row = try Row.fetchOne(db, sql: try getBalanceQuery(buckets: getTreeAtBucket(bucket!, db: db), statusTypes: Transaction.StatusTypes.allCases.filter({status in
                    status.rawValue != Transaction.StatusTypes.Submitted.rawValue
                })), arguments: []) {
                    atb = row["Amount"]
                }
                
                return BucketBalance(posted: pb, available: ab, postedInTree: ptb, availableInTree: atb)
            } catch {
                print("Error while calculating balance for bucket")
                throw error
            }
        } else {
            return BucketBalanceRequest.defaultValue
        }
    }
    
    private func getTreeAtBucket(_ bucket: Bucket, db: Database) throws -> [Bucket]{
        var result = try bucket.tree.fetchAll(db)
        result.append(bucket)
        return result
    }
    
    private func getBalanceQuery(buckets: [Bucket], statusTypes: [Transaction.StatusTypes]) throws -> String {
        var statusIDs: [Int] = []
        for status in statusTypes {
            statusIDs.append(status.rawValue)
        }
        let statusStr: String = statusIDs.map({ val in return "\(val)" }).joined(separator: ", ")
        
        var bucketIDs: [Int64] = []
        for bucket in buckets {
            if bucket.id != nil {
                bucketIDs.append(bucket.id!)
            }
        }
        let bucketStr: String = bucketIDs.map({ val in return "\(val)" }).joined(separator: ", ")
        
        return """
                    SELECT IFNULL(SUM(Amount), 0) AS \"Amount\" FROM (
                        SELECT -1*SUM(Amount) AS \"Amount\" FROM Transactions WHERE SourceBucket IN (\(bucketStr)) AND Status IN (\(statusStr))
                    
                        UNION ALL
                    
                        SELECT SUM(Amount) AS \"Amount\" FROM Transactions WHERE DestBucket IN (\(bucketStr)) AND Status IN (\(statusStr))
                    )
            """
    }
}
