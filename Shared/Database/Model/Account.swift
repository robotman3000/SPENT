//
//  Account.swift
//  SPENT
//
//  Created by Eric Nims on 1/27/22.
//

import Foundation
import GRDB
import GRDBQuery
import Combine

struct Account: Identifiable, Codable, Hashable {
    var id: Int64?
    var name: String
}

// SQL Database support
extension Account: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "Accounts"
    
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

// Relationships
extension Account {
    static let transactions = hasMany(Transaction.self)
    var transactions: QueryInterfaceRequest<Transaction> {
        request(for: Account.transactions)
    }
    
    static let buckets = hasMany(Bucket.self, through: transactions, using: Transaction.bucket)
    var buckets: QueryInterfaceRequest<Bucket> {
        request(for: Account.buckets)
    }
    //TODO: Balance
}

struct AllAccounts: Queryable {
    static var defaultValue: [Account] { [] }
    func publisher(in dbQueue: DatabaseQueue) -> AnyPublisher<[Account], Error> {
        ValueObservation
            .tracking(Account.fetchAll)
            // The `.immediate` scheduling feeds the view right on subscription,
            // and avoids an initial rendering with an empty list:
            .publisher(in: dbQueue, scheduling: .immediate)
            .eraseToAnyPublisher()
    }
}

struct AccountTransactions: Queryable {
    static var defaultValue: [Transaction] { [] }
    let account: Account
    let bucket: Bucket?
    func publisher(in dbQueue: DatabaseQueue) -> AnyPublisher<[Transaction], Error> {
        ValueObservation
            .tracking(Transaction.all().filter(account: account).fetchAll)
            // The `.immediate` scheduling feeds the view right on subscription,
            // and avoids an initial rendering with an empty list:
            .publisher(in: dbQueue, scheduling: .immediate)
            .eraseToAnyPublisher()
    }
}
