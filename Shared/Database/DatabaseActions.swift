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
    
    func execute(db: Database) throws {
        switch self {
        case let .deleteAccount(account):
            try deleteAccount(db, account)
        case let .deleteTransaction(transaction):
            try deleteTransaction(db, transaction)
        }
    }
}

extension DatabaseActions {
    private func deleteAccount(_ db: Database, _ account: Account) throws {
        try account.delete(db)
    }
    
    private func deleteTransaction(_ db: Database, _ transaction: Transaction) throws {
        try transaction.delete(db)
    }
}

protocol DatabaseAction {
    func execute(db: Database) throws
}
