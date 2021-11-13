//
//  TransactionRequest.swift
//  SPENT
//
//  Created by Eric Nims on 5/12/21.
//


import GRDB
import Combine
import SwiftUI

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

struct BucketQuery: Queryable {
    static var defaultValue: [BucketModel] = []
    
    func fetchValue(_ db: Database) throws -> [BucketModel] {
        let buckets = try Bucket.fetchAll(db)
        var models: [BucketModel] = []
        for bucket in buckets {
            models.append(BucketModel(bucket: bucket, balance: nil))
        }
        return models
    }
    
    static func publisher(withReader: DatabaseReader) -> AnyPublisher<Array<BucketModel>, Error> {
        let request = BucketQuery()
        let publisher = ValueObservation
            .tracking(request.fetchValue)
            .publisher(
                in: withReader, scheduling: .async(onQueue: DispatchQueue.init(label: "UI Database Queue"))).eraseToAnyPublisher()
        //print("filter return pblisher")
        return publisher
    }
}
