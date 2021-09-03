//
//  TransactionData.swift
//  SPENT
//
//  Created by Eric Nims on 7/3/21.
//

import Foundation
import GRDB

struct TransactionData: Identifiable, FetchableRecord, Decodable, Hashable {
    var id: Int64 {
        get {
            transaction.id!
        }
    }
    
    // Database Data
    var tags: [Tag]
    var source: Bucket?
    var destination: Bucket?
    var transaction: Transaction
    var splitMembers: [Transaction]
    
    private enum CodingKeys: String, CodingKey {
        case tags = "tags", source = "source", destination = "destination", transaction = "transaction", splitMembers = "splitMembers"
    }
    
    // Cached computed properties
    var contextType: Transaction.TransType = .Deposit
    var transactionType: Transaction.TransType = .Deposit
    var dateFormatted: String = ""
    var postedFormatted: String?
    var amountFormatted: String = ""
    var splitType: Transaction.TransType = .Deposit
    var splitMember: Transaction?
    var splitAmount: Int = 0
    
    mutating func preCalcValues(contextBucket: Bucket){
        contextType = transaction.getType(convertTransfer: true, bucket: contextBucket.id)
        transactionType = transaction.type
        dateFormatted = transaction.date.transactionFormat
        postedFormatted = transaction.posted?.transactionFormat
        amountFormatted = transaction.amount.currencyFormat
        splitType = Transaction.getSplitDirection(members: splitMembers)
        splitMember = Transaction.getSplitMember(splitMembers, bucket: contextBucket)
        splitAmount = Transaction.amountSum(splitMembers)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(transaction)
    }
}
