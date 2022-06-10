//
//  TransferFormModel.swift
//  SPENT
//
//  Created by Eric Nims on 6/8/22.
//

import GRDB
import SwiftUI

class TransferFormModel: FormModel {
    fileprivate var transfer: Transfer?
    fileprivate var sourceTransaction: Transaction?
    fileprivate var destinationTransaction: Transaction?
    
    @Published var status: Transaction.StatusTypes = .Uninitiated
    @Published var entryDate: Date = Date()
    @Published var postDate: Date = Date()
    @Published var amount: String = ""
    @Published var memo: String = ""
    
    @Published var sourceAccount: Account?
    @Published var destinationAccount: Account?
    @Published var accountChoices: [Account] = []
    
    init(transfer: Transfer?){
        //TODO: Prevent loading a transfer with a nil id
        self.transfer = transfer
    }
    
    func loadState(withDatabase: Database) throws {
        if let transfer = transfer {
            let sourceTransaction = try transfer.sourceTransaction.fetchOne(withDatabase)
            let destinationTransaction = try transfer.destinationTransaction.fetchOne(withDatabase)
            
            // TODO: Throw error if either transaction is nil
            //TODO: Correctly handle when the source and dest values differ by showing nothing but still track the difference
            status = sourceTransaction!.status
            entryDate = sourceTransaction!.entryDate
            postDate = sourceTransaction!.postDate ?? Date()
            amount = NSDecimalNumber(value: abs(sourceTransaction!.amount)).dividing(by: 100).stringValue
            memo = sourceTransaction!.memo
            
            sourceAccount = try sourceTransaction?.account.fetchOne(withDatabase)
            destinationAccount = try destinationTransaction?.account.fetchOne(withDatabase)
            
            self.sourceTransaction = sourceTransaction
            self.destinationTransaction = destinationTransaction
        } else {
            // This is a new transfer
            sourceTransaction = Transaction(id: nil, status: .Uninitiated, amount: 0, payee: "", memo: "", entryDate: Date(), postDate: nil, bucketID: nil, accountID: -1)
            destinationTransaction = Transaction(id: nil, status: .Uninitiated, amount: 0, payee: "", memo: "", entryDate: Date(), postDate: nil, bucketID: nil, accountID: -1)
        }
    
        accountChoices = try Account.order(Account.Columns.name.asc).fetchAll(withDatabase)
    }
    
    func validate() throws {
        if sourceAccount?.id == destinationAccount?.id {
            throw FormValidationError("The from and to fields must be different")
        }
        
        if sourceAccount?.id == nil || destinationAccount?.id == nil {
            throw FormValidationError("Please provide a value for the From and To fields")
        }
        
        if amount.isEmpty {
            throw FormValidationError("Please provide a valid amount")
        }

        if status.rawValue >= Transaction.StatusTypes.Complete.rawValue {
            // If entryDate is greater than postDate
            if Calendar.current.compare(entryDate, to: postDate, toGranularity: .day) == .orderedDescending {
                // Prevent a transaction that posted before it was made
                throw FormValidationError("A transfer cannot have a post date before it's creation date")
            }
        }
    }
    
    func submit(withDatabase: Database) throws {
        // Update the transaction from the form data
        let destinationAmount = abs(NSDecimalNumber(string: amount).multiplying(by: 100).intValue)
        let sourceAmount = destinationAmount * -1
        updateTransaction(&sourceTransaction!, status: status, entryDate: entryDate, postDate: postDate, amount: sourceAmount, memo: memo, account: sourceAccount!)
        updateTransaction(&destinationTransaction!, status: status, entryDate: entryDate, postDate: postDate, amount: destinationAmount, memo: memo, account: destinationAccount!)
        
        // Write to the db
        try sourceTransaction?.save(withDatabase)
        try destinationTransaction?.save(withDatabase)
        
        if transfer == nil {
            // Now that the transactions have been saved we can use their newly assigned id's to create the transfer record
            transfer = Transfer(id: nil, sourceTransactionID: sourceTransaction!.id!, destinationTransactionID: destinationTransaction!.id!)
            try transfer!.save(withDatabase)
        }
    }
    
    private func updateTransaction(_ transaction: inout Transaction, status: Transaction.StatusTypes, entryDate: Date, postDate: Date, amount: Int, memo: String, account: Account) {
        transaction.status = status
        transaction.entryDate = entryDate
        if status.rawValue >= Transaction.StatusTypes.Complete.rawValue {
            transaction.postDate = postDate
        } else {
            transaction.postDate = nil
        }
        transaction.accountID = account.id!
        transaction.payee = "Account Transfer" // Transfers don't need payees
        transaction.memo = memo
        transaction.amount = amount
    }
}
