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
    
    func execute(db: Database) throws {
        switch self {
        case let .deleteAccount(account):
            try deleteAccount(db, account)
        }
    }
}

extension DatabaseActions {
    private func deleteAccount(_ db: Database, _ account: Account) throws {
        try account.delete(db)
    }
}

protocol DatabaseAction {
    func execute(db: Database) throws
}
