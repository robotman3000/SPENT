//
//  TTransactionRequest.swift
//  macOS
//
//  Created by Eric Nims on 10/19/21.
//

import Foundation
import GRDB

struct TransactionRequest: DatabaseRequest {
    var forID: Int64
    var viewingBucket: Int64?
    
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
                var bidFilter = ""
                if let bucketID = viewingBucket {
                    bidFilter = "AND bid == \(bucketID)"
                }
                let balance = try TransactionBalance.fetchOne(db, sql: "SELECT * FROM \(TransactionBalance.databaseTableName) WHERE tid == \(forID) \(bidFilter)")
                let splitMembers = try transaction.splitMembers.fetchAll(db)
                
                // Now for "computed" values
                var splitType: Transaction.TransType = .Deposit
                var splitAmount: Int = 0
                var splitMember: Transaction? = nil
                var contextType: Transaction.TransType = .Deposit
                
                if transaction.group != nil {
                    splitType = Transaction.getSplitDirection(members: splitMembers)
                    splitAmount = Transaction.amountSum(splitMembers)
                }
                
                if let bucketID = viewingBucket {
                    contextType = transaction.getType(convertTransfer: true, bucket: bucketID)
                    if transaction.group != nil {
                        splitMember = Transaction.getSplitMember(splitMembers, forBucket: bucketID)
                    }
                }
                return TransactionModel(transaction: transaction, tags: tags, source: source, destination: destination, balance: balance, splitMembers: splitMembers, contextType: contextType, splitType: splitType, splitMember: splitMember, splitAmount: splitAmount)
            }
        }
        throw RequestFetchError("requestValue failed for TransactionRequest")
    }
}
