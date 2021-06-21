//
//  UIDatabaseConnector.swift
//  SPENT
//
//  Created by Eric Nims on 6/19/21.
//

import Foundation
import SwiftUI

private func printError(error: Error) {
    print(error)
}

func updateTransaction(_ data: inout Transaction, database: AppDatabase, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
    print(data)
    do {
        try database.saveTransaction(&data)
        onComplete()
    } catch {
        onError(error)
    }
}

func deleteTransaction(_ id: Int64, database: AppDatabase, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
    do {
        try database.deleteTransactions(ids: [id])
        onComplete()
    } catch {
        onError(error)
    }
}

func getEmptyTransaction() -> Binding<Transaction> {
    return Binding<Transaction>(
        get: {
            Transaction(id: nil, status: .Uninitiated, date: Date(), amount: 0)
        },
        set: { _ in
            print("Trans binding: ignoring set")
        }
    )
}

func updateBucket(_ data: inout Bucket, database: AppDatabase, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
    print(data)
    do {
        try database.saveBucket(&data)
        onComplete()
    } catch {
        onError(error)
    }
}

func deleteBucket(_ id: Int64, database: AppDatabase, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
    do {
        try database.deleteBucket(id: id)
        onComplete()
    } catch {
        onError(error)
    }
}

func updateTag(_ data: inout Tag, database: AppDatabase, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
    print(data)
    do {
        try database.saveTag(&data)
        onComplete()
    } catch {
        onError(error)
    }
}

func deleteTag(_ id: Int64, database: AppDatabase, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
    do {
        try database.deleteTag(id: id)
        onComplete()
    } catch {
        onError(error)
    }
}

func updateSchedule(_ data: inout Schedule, database: AppDatabase, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
    print(data)
    do {
        try database.saveSchedule(&data)
        onComplete()
    } catch {
        onError(error)
    }
}

func deleteSchedule(_ id: Int64, database: AppDatabase, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
    do {
        try database.deleteSchedule(id: id)
        onComplete()
    } catch {
        onError(error)
    }
}
