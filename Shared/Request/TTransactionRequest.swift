//
//  TTransactionRequest.swift
//  macOS
//
//  Created by Eric Nims on 10/19/21.
//

import Foundation
import GRDB

struct TTransactionRequest: DatabaseRequest {
    var forID: Int64
    
    func requestValue(_ db: Database) throws -> TransactionModel {

//
//        let balance = CommonTableExpression(
//            named: "transactionBalance",
//            sql: "SELECT * FROM transactionBalance"
//        )
//
//        let balanceAssociation = Transaction.association(
//            to: balance,
//            on: { transactions, balance in
//                // If ancestorID is nil that means the bucket is the ancestor
//                transactions[Column("id")] == balance[Column("tid")] && bucket.ancestorID ?? bucket.id! == balance[Column("aid")]
//            })

        do {
            let transaction = try Transaction.fetchOne(db, id: forID)
            if let transaction = transaction {
                let source = try transaction.source.fetchOne(db)
                let destination = try transaction.destination.fetchOne(db)
                let tags = try transaction.tags.fetchAll(db)
                let balance = try TransactionBalance.fetchOne(db, sql: "SELECT * FROM \(TransactionBalance.databaseTableName) WHERE tid == \(forID)")
                return TransactionModel(transaction: transaction, tags: tags, source: source, destination: destination, balance: balance)
            }
        }
        throw RequestFetchError()
    }
}
