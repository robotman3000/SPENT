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
        request(for: Account.buckets).distinct()
    }
    
    static let balance = hasOne(AccountBalance.self)
    var balance: QueryInterfaceRequest<AccountBalance> {
        request(for: Account.balance)
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
                
                let transactionTypeCTE = CommonTableExpression(
                    named: "transType",
                    sql: "SELECT * FROM TransactionType")
                
                let typeAssociation = Transaction.association(
                    to: transactionTypeCTE,
                    on: { left, right in
                        left[Column("id")] == right[Column("id")]
                    })
                
                var request = Transaction.all()
                    .including(required: Transaction.account)
                    .including(optional: Transaction.bucket)
                    .with(runningBalanceCTE)
                    .including(required: association)
                    .with(transactionTypeCTE)
                    .including(required: typeAssociation)
                    .filter(account: account)
                
                if let bucket = bucket {
                    request = request.filter(bucket: bucket)
                }
                return try TransactionInfo.fetchAll(db, request)
            })
            // The `.immediate` scheduling feeds the view right on subscription,
            // and avoids an initial rendering with an empty list:
            .publisher(in: dbQueue, scheduling: .immediate)
            .eraseToAnyPublisher()
    }
}

struct AccountBuckets: Queryable {
    static var defaultValue: [BucketInfo] = []
    let forAccount: Account
    
    func publisher(in database: DatabaseQueue) -> AnyPublisher<[BucketInfo], Error> {
        //TODO: This implementation may be causing GRDB to run the query every time the view changes
        ValueObservation
            .tracking(BucketBalance.all()
                        .filter(account: forAccount)
                        .including(required: BucketBalance.bucket)
                        .including(required: BucketBalance.account)
                        .asRequest(of: BucketInfo.self)
                        .fetchAll)
            // The `.immediate` scheduling feeds the view right on subscription,
            // and avoids an initial rendering with an empty list:
            .publisher(in: database, scheduling: .immediate)
            .eraseToAnyPublisher()
    }
}

struct AccountBalanceQuery: Queryable {
    static var defaultValue: AccountBalance = AccountBalance(id: -1, posted: 0, available: 0, allocatable: 0)
    let account: Account
    
    func publisher(in database: DatabaseQueue) -> AnyPublisher<AccountBalance, Error> {
        ValueObservation
            .tracking({ db in
                var balance = try AccountBalance.filter(Column("Id") == account.id).fetchOne(db)
                if balance == nil {
                    balance = AccountBalance(id: account.id ?? -1, posted: 0, available: 0, allocatable: 0)
                }
                return balance!
            })
            // The `.immediate` scheduling feeds the view right on subscription,
            // and avoids an initial rendering with an empty list:
            .publisher(in: database, scheduling: .immediate)
            .eraseToAnyPublisher()
    }
}
