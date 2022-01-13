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
    var display: DisplayTransaction?
    // Cached computed properties
    var contextType: Transaction.TransType = .Deposit
    var splitType: Transaction.TransType = .Deposit
    var splitMember: Transaction?
    var splitAmount: Int = 0
    
    // id, status, sourcebucket, destbucket, memo, payee, group, v_type, amount, bucket, account, date, isallocation, postedrunning, availablerunning
}

struct TransactionModel2 {
    var transaction: DisplayTransaction
    var tags: [Tag] = []
    var account: Bucket?
    var bucket: Bucket?
}
