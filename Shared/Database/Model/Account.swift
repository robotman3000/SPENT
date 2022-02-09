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
}

struct AllAccounts: Queryable {
    static var defaultValue: [AccountInfo] { [] }
    func publisher(in dbQueue: DatabaseQueue) -> AnyPublisher<[AccountInfo], Error> {
        ValueObservation
            .tracking(AccountInfo.fetchAll)
            // The `.immediate` scheduling feeds the view right on subscription,
            // and avoids an initial rendering with an empty list:
            .publisher(in: dbQueue, scheduling: .immediate)
            .eraseToAnyPublisher()
    }
}

struct AccountTransactions: Queryable {
    static var defaultValue: [TransactionInfo] { [] }
    let account: Account
    let bucket: Bucket?
    func publisher(in dbQueue: DatabaseQueue) -> AnyPublisher<[TransactionInfo], Error> {
        ValueObservation
            .tracking({ db in
                
                let runningBalanceCTE = CommonTableExpression(
                    named: "runningBalance",
                    request: AccountRunningBalance.all().filter(Column("AccountID") == account.id))
                
                let association = Transaction.association(
                    to: runningBalanceCTE,
                    on: { left, right in
                        left[Column("id")] == right[Column("TransactionID")]
                    })
                
                let request = Transaction.all()
                    .filter(account: account)
                    .including(required: Transaction.account)
                    .including(optional: Transaction.bucket)
                    .with(runningBalanceCTE)
                    .including(required: association)
                return try TransactionInfo.fetchAll(db, request)
            })
            // The `.immediate` scheduling feeds the view right on subscription,
            // and avoids an initial rendering with an empty list:
            .publisher(in: dbQueue, scheduling: .immediate)
            .eraseToAnyPublisher()
    }
}
