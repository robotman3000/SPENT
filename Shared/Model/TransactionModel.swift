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

    // Cached computed properties
    var contextType: Transaction.TransType = .Deposit
    var splitType: Transaction.TransType = .Deposit
    var splitMember: Transaction?
    var splitAmount: Int = 0
}
