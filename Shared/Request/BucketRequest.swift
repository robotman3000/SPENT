//
//  TransactionRequest.swift
//  SPENT
//
//  Created by Eric Nims on 5/12/21.
//


import GRDB

/// Make `BucketRequest` able to be used with the `@Query` property wrapper.
struct BucketRequest: DatabaseRequest {   
    var forID: Int64
    
    func requestValue(_ db: Database) throws -> BucketModel {
        //print("brequest begin")
        do {
            let bucket = try Bucket.fetchOne(db, id: forID)
            let balance = try BucketBalance.fetchOne(db, sql: "SELECT * FROM \(BucketBalance.databaseTableName) WHERE bid == \(forID)")
            if let bucket = bucket {
                //print("brequest was good")
                return BucketModel(bucket: bucket, balance: balance)
            }
        }
        //print("brequest was bad")
        throw RequestFetchError()
    }
}
