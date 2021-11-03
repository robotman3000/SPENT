//
//  TransactionFormModel.swift
//  macOS
//
//  Created by Eric Nims on 11/3/21.
//

import Foundation

struct TransactionFormModel {
    var transaction: Transaction
    
    var selectedBucket: Bucket?
    var bucketChoices: [Bucket] = []
    
    var sPostDate: Date = Date()
    var dPostDate: Date = Date()
    var payee: String = ""
    var transType: Transaction.TransType = .Withdrawal
    var amount: String = ""
}
