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
    var excludeAllocations: Bool = true
    var excludeCleared: Bool = true
    var direction: Transaction.OrderDirection = .ascending
    var ordering: Transaction.Ordering = .byPostDate
    
    func publisher(in dbQueue: DatabaseQueue) -> AnyPublisher<[TransactionInfo], Error> {
        ValueObservation
            .tracking({ db in
                let runningBalanceCTE = CommonTableExpression(
                    named: "runningBalance",
                    request: AccountRunningBalance.all().filter(Column("AccountID") == account.id))
                
                let runningBalanceAssoc = Transaction.association(
                    to: runningBalanceCTE,
                    on: { left, right in
                        left[Column("id")] == right[Column("TransactionID")]
                    })
                
                let transferCTE = CommonTableExpression(
                    named: "transfer",
                    sql: "SELECT * FROM Transfers")
                
                let transferAssoc = Transaction.association(
                    to: transferCTE,
                    on: { left, right in
                        left[Column("id")] == right[Column("SourceTransactionID")] ||
                        left[Column("id")] == right[Column("DestinationTransactionID")]
                    })
                
                let splitCTE = CommonTableExpression(
                    named: "split",
                    sql: "SELECT * FROM SplitTransactions")
                
                let splitAssoc = Transaction.association(
                    to: splitCTE,
                    on: { left, right in
                        left[Column("id")] == right[Column("TransactionID")]
                    })
                
                var request = Transaction.all()
                    .including(required: Transaction.account)
                    .including(optional: Transaction.bucket)
                    .including(all: Transaction.tags)
                    .with(transferCTE)
                    .including(optional: splitAssoc)
                    .with(runningBalanceCTE)
                    .including(optional: transferAssoc)
                    .with(splitCTE)
                    .including(optional: runningBalanceAssoc)
                    .filter(account: account)
                
                if excludeAllocations {
                    request = request.filter(literal: "SplitUUID IS NULL")
                }

                if excludeCleared {
                    request = request.filter(literal: "Status NOT IN (0, 6)")
                }
                
                if let bucket = bucket {
                    request = request.filter(bucket: bucket)
                }
                
                if ordering != .byPostDate {
                    request = request.order(ordering.getOrdering(direction))
                } else {
                    request = request.order(sql: "IFNULL(PostDate, EntryDate) " + (direction == .ascending ? "ASC" : "DESC"))
                }
                
                let result = try TransactionInfo.fetchAll(db, request)
                return result
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
                        .order(literal: "Buckets.Name ASC")
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
    static var defaultValue: AccountBalance = AccountBalance(id: -1, posted: 0, available: 0, allocatable: 0, estimated: 0)
    let account: Account
    
    func publisher(in database: DatabaseQueue) -> AnyPublisher<AccountBalance, Error> {
        ValueObservation
            .tracking({ db in
                var balance = try AccountBalance.filter(Column("Id") == account.id).fetchOne(db)
                if balance == nil {
                    balance = AccountBalance(id: account.id ?? -1, posted: 0, available: 0, allocatable: 0, estimated: 0)
                }
                return balance!
            })
            // The `.immediate` scheduling feeds the view right on subscription,
            // and avoids an initial rendering with an empty list:
            .publisher(in: database, scheduling: .immediate)
            .eraseToAnyPublisher()
    }
}
