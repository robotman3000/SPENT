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
    var includeAggregate: Bool = false
    
    func requestValue(_ db: Database) throws -> BucketModel {
        do {
            let bucket = try Bucket.fetchOne(db, id: forID)
            var balance = try BucketBalance.fetchOne(db, sql: "SELECT * FROM \(BucketBalance.databaseTableName) WHERE id == \(forID)")
            
            if let bucket = bucket {
                if balance == nil {
                    // This means the balance table has no value for this bucket.
                    // I.E. It has no transactions
                    balance = BucketBalance(bucketID: bucket.id!, available: 0, posted: 0)
                }
                if includeAggregate {
                    try queryAggregates(withDatabase: db, balance: &balance!)
                }
                
                return BucketModel(bucket: bucket, balance: balance)
            }
        } catch {
            print(error)
        }
        throw RequestFetchError("requestValue failed for BucketRequest")
    }
    
    private func queryAggregates(withDatabase: Database, balance: inout BucketBalance) throws {
        //TODO: Move this into the main model query
        let bkts = CommonTableExpression(
            recursive: true,
            named: "bkts",
            sql: """
                SELECT id FROM Buckets e WHERE e.id = \(balance.bucketID)
                UNION ALL
                SELECT e.id FROM Buckets e
                JOIN bkts c ON c.id = e.Parent
            """
        )
        let bal = try BucketBalance.select(sql: "IFNULL(id, -1) AS \"id\", posted, available, SUM(available) AS \"availableTree\", SUM(posted) AS \"postedTree\"").filter(sql: "id IN (SELECT * FROM bkts)").with(bkts).fetchOne(withDatabase)
        balance.availableTree = bal?.availableTree
        balance.postedTree = bal?.postedTree
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
        return publisher
    }
}
