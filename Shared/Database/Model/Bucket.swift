//
//  Bucket.swift
//  SPENT
//
//  Created by Eric Nims on 5/14/21.
//

import Foundation
import GRDB
import GRDBQuery
import Combine

struct Bucket: Identifiable, Codable, Hashable {
    var id: Int64?
    var name: String
}

// SQL Database support
extension Bucket: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "Buckets"
    
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
    
    // Define database columns from CodingKeys
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
    }
}

extension Bucket {
    static let transactions = hasMany(Transaction.self)
    var transactions: QueryInterfaceRequest<Transaction> {
        request(for: Bucket.transactions)
    }
    
    static let accounts = hasMany(Account.self, through: transactions, using: Transaction.account)
    var accounts: QueryInterfaceRequest<Account> {
        request(for: Bucket.accounts)
    }
    //TODO: Balance
}

struct BucketsForAccount: Queryable {
    static var defaultValue: [Bucket] { [] }
    let account: Account
    func publisher(in dbQueue: DatabaseQueue) -> AnyPublisher<[Bucket], Error> {
        ValueObservation
            .tracking(account.buckets.fetchAll)
            // The `.immediate` scheduling feeds the view right on subscription,
            // and avoids an initial rendering with an empty list:
            .publisher(in: dbQueue, scheduling: .immediate)
            .eraseToAnyPublisher()
    }
}
