//
//  DatabaseActions.swift
//  macOS
//
//  Created by Eric Nims on 2/1/22.
//

import Foundation
import GRDB

enum DatabaseActions: DatabaseAction {
    case deleteAccount(Account)
    case deleteTransaction(Transaction)
    case deleteSplitTransaction(SplitTransaction)
    case deleteBucket(Bucket)
    case setTransactionsStatus(Transaction.StatusTypes, [Transaction])
    
    func execute(db: Database) throws {
        switch self {
        case let .deleteAccount(account):
            try deleteAccount(db, account)
        case let .deleteTransaction(transaction):
            try deleteTransaction(db, transaction)
        case let .deleteSplitTransaction(split):
            try deleteSplitTransaction(db, split)
        case let .deleteBucket(bucket):
            try deleteBucket(db, bucket)
        case let .setTransactionsStatus(toStatus, forTransactions):
            try setTransactionsStatus(db, toStatus, forTransactions)
        }
    }
}

extension DatabaseActions {
    private func deleteAccount(_ db: Database, _ account: Account) throws {
        try account.delete(db)
    }
    
    private func deleteTransaction(_ db: Database, _ transaction: Transaction) throws {
        //TODO: What if the transaction is actually a transfer?
        try transaction.delete(db)
    }

    private func deleteSplitTransaction(_ db: Database, _ split: SplitTransaction) throws {
        // Fetch all the split transaction records with the same uuid
        let splits = try SplitTransaction.filter(SplitTransaction.Columns.splitUUID == split.splitUUID.uuidString).fetchAll(db)
        
        // Get the list of linked transactions
        let transactionIDs = splits.map { $0.transactionID }
        
        // Delete split records first to satisfy foreign key requirements
        try SplitTransaction.filter(ids: splits.map{ $0.id! }).deleteAll(db)
        
        // Delete the transactions
        try Transaction.filter(ids: transactionIDs).deleteAll(db)
    }
    
    private func deleteBucket(_ db: Database, _ bucket: Bucket) throws {
        try bucket.delete(db)
    }
    
    private func setTransactionsStatus(_ db: Database, _ toStatus: Transaction.StatusTypes, _ forTransactions: [Transaction]) throws {
        for var transaction in forTransactions {
            //TODO: What if the transaction is actually a transfer?
            transaction.status = toStatus
            try transaction.save(db)
        }
    }
}

protocol DatabaseAction {
    func execute(db: Database) throws
}
