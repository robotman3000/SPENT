//
//  TransactionFormModel.swift
//  SPENT
//
//  Created by Eric Nims on 6/8/22.
//

import GRDB
import SwiftUI

class TransactionFormModel: FormModel {
    fileprivate var transaction: Transaction
    
    @Published var status: Transaction.StatusTypes
    @Published var entryDate: Date
    @Published var postDate: Date
    @Published var amount: String
    @Published var type: Transaction.TransType
    @Published var payee: String
    @Published var memo: String
    
    @Published var selectedBucket: Bucket?
    @Published var bucketChoices: [Bucket]
    
    @Published var selectedAccount: Account?
    @Published var accountChoices: [Account]
    
    init(transaction: Transaction, contextBucket: Int64? = nil){
        amount = ""
        type = .Withdrawal
        bucketChoices = []
        accountChoices = []
        self.transaction = transaction
        self.status = transaction.status
        self.entryDate = transaction.entryDate
        self.postDate = transaction.postDate ?? Date()
        self.memo = transaction.memo
        self.payee = transaction.payee
        
        type = transaction.amount < 0 ? .Withdrawal : .Deposit
        amount = NSDecimalNumber(value: abs(transaction.amount)).dividing(by: 100).stringValue
        
        //self.contextBucketID = contextBucket
    }
    
    func loadState(withDatabase: Database) throws {
        bucketChoices = try Bucket.all().order(Bucket.Columns.name.asc).fetchAll(withDatabase)
        accountChoices = try Account.all().order(Account.Columns.name.asc).fetchAll(withDatabase)

        selectedBucket = try transaction.bucket.fetchOne(withDatabase)
        selectedAccount = try transaction.account.fetchOne(withDatabase)
    }
    
    func validate() throws {
        if amount.isEmpty || selectedAccount == nil {
            throw FormValidationError("Form is missing required values")
        }

        if status.rawValue >= Transaction.StatusTypes.Complete.rawValue {
            if Calendar.current.compare(entryDate, to: postDate, toGranularity: .day) == .orderedDescending {
                // Prevent a transaction that posted before it was made
                throw FormValidationError("A transaction cannot have a post date before it's entry date")
            }
        }
    }
    
    func submit(withDatabase: Database) throws {
        transaction.status = status
        transaction.entryDate = entryDate
        transaction.payee = payee
        transaction.memo = memo
        
        let amount = abs(NSDecimalNumber(string: self.amount).multiplying(by: 100).intValue)
        transaction.amount = type == .Withdrawal ? amount * -1 : amount
        
        transaction.bucketID = selectedBucket?.id
        transaction.accountID = selectedAccount!.id! // This must never be nil when we submit, so crash if it is
        
        if status.rawValue >= Transaction.StatusTypes.Complete.rawValue {
            transaction.postDate = postDate
        } else {
            transaction.postDate = nil
        }
        
        try transaction.save(withDatabase)
    }
}
