//
//  TransactionModel.swift
//  macOS
//
//  Created by Eric Nims on 10/19/21.
//

import Foundation
import GRDB

struct TransactionModel {
    var transaction: Transaction
    var tags: [Tag] = []
    var source: Bucket?
    var destination: Bucket?
    var balance: TransactionBalance?
    var splitMembers: [Transaction] = []
    // TODO: update functions
    
    
    // Cached computed properties
//    var contextType: Transaction.TransType = .Deposit
//    var dateFormatted: String = ""
//    var postedFormatted: String?
//    var amountFormatted: String = ""
//    var splitType: Transaction.TransType = .Deposit
//    var splitMember: Transaction?
//    var splitAmount: Int = 0
//    
//    mutating func preCalcValues(contextBucket: Bucket){
//        contextType = transaction.getType(convertTransfer: true, bucket: contextBucket.id)
//        dateFormatted = transaction.date.transactionFormat
//        //TODO: Add support for source and dest post dates
//        postedFormatted = transaction.sourcePosted?.transactionFormat
//        amountFormatted = transaction.amount.currencyFormat
//        splitType = Transaction.getSplitDirection(members: splitMembers)
//        splitMember = Transaction.getSplitMember(splitMembers, bucket: contextBucket)
//        splitAmount = Transaction.amountSum(splitMembers)
//    }
//    
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(transaction)
//    }
}
