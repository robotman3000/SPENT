//
//  SplitTransactionFormModel.swift
//  SPENT
//
//  Created by Eric Nims on 6/8/22.
//

import GRDB
import SwiftUI

class SplitTransactionFormModel: FormModel {
    var splitUUID: UUID = UUID()
    fileprivate var split: SplitTransaction?
    fileprivate var headTransaction: Transaction?
    @Published var members: [SplitMemberFormModel] = []
    
    @Published var accountChoices: [Account] = []
    @Published var bucketChoices: [Bucket] = []
    @Published var selectedAccount: Account?
    @Published var type: Transaction.TransType = .Deposit
    
    @Published var memo: String = ""
    @Published var amount: String = "0"
    @Published var date: Date = Date()
    @Published var status: Transaction.StatusTypes = .Void

    init(model: SplitTransaction?){
        self.split = model
    }
    
    func updateSplitMember(_ member: SplitMemberFormModel){
        if let index = members.firstIndex(where: { $0.id == member.id }) {
            // Delete the old version
            members.remove(at: index)
        }
        // Insert the new/created version
        members.append(member)
    }
    
    func deleteSplitMember(_ member: SplitMemberFormModel){
        if let index = members.firstIndex(where: { $0.id == member.id }) {
            if members[index].editStatus == .inMemory {
                members[index].editStatus = .memoryDelete
            } else {
                members[index].editStatus = .databaseDeleted
            }
        }
        
        members.removeAll(where: { $0.editStatus == .memoryDelete })
    }
    
    func loadState(withDatabase: Database) throws {
        if let split = split {
            splitUUID = split.splitUUID
            
            // The split is pre-existing.
            // Load the split head
            headTransaction = try split.headTransaction.fetchOne(withDatabase)
            
            // Load the other split members
            let dbMembers = try split.members.fetchAll(withDatabase)
            
            // Wrap the database objects in a container
            members = try dbMembers.map({ dbMember in
                // This container fetches the associated transactions from the db for each member
                try SplitMemberFormModel(withDatabase: withDatabase, model: dbMember)
            })
            
            // Load the selected account
            selectedAccount = try headTransaction?.account.fetchOne(withDatabase)
        } else {
            // We must create a new split but we can't make it here because we don't have the foreign key values yet.
            
            // Create a new head transaction for the split
            headTransaction = Transaction(id: nil, status: .Uninitiated, amount: 0, payee: "", memo: "", entryDate: Date(), postDate: nil, bucketID: nil, accountID: -1)
        }
        
        guard headTransaction != nil else {
            throw FormInitializeError("Head Transaction cannot be nil")
        }
        
        // Load the head transaction state
        memo = headTransaction!.memo
        amount = NSDecimalNumber(value: abs(headTransaction!.amount)).dividing(by: 100).stringValue
        date = headTransaction!.entryDate
        status = headTransaction!.status
        
        // The deposit and withdrawal values aren't backwards. It's relative to the head transaction
        type = (headTransaction!.amount <= 0 ? .Deposit : .Withdrawal)
        
        // Fetch select box choices
        accountChoices = try Account.all().order(Bucket.Columns.name.asc).fetchAll(withDatabase)
        bucketChoices = try Bucket.all().order(Account.Columns.name.asc).fetchAll(withDatabase)
    }
    
    func validate() throws {
        // nil protection
        if amount.isEmpty || selectedAccount == nil || members.isEmpty {
            throw FormValidationError("Form is missing required values")
        }
        
        for member in members {
            guard member.bucket != nil else {
                throw FormValidationError("Invalid value")
            }
            
            //TODO: Include any other validation of the members here
        }
        // TODO: Prevent over spending a split
//        if (headAmount - splitAmount < 0){
//            throw FormValidationError()
//        }
    }
    
    func submit(withDatabase: Database) throws {
        guard headTransaction != nil else {
            throw FormValidationError("Split transaction head cannot be nil")
        }
        
        let destinationAmount = abs(NSDecimalNumber(string: amount).multiplying(by: 100).intValue)
        let sourceAmount = destinationAmount * -1
        
        headTransaction!.memo = memo
        headTransaction!.status = status
        headTransaction!.entryDate = date
        headTransaction!.accountID = selectedAccount!.id!
        headTransaction!.amount = (type == .Deposit ? sourceAmount : destinationAmount)
        try headTransaction!.save(withDatabase)
        
        for var member in members {
            if member.editStatus == .databaseDeleted {
                // The schema uses cascade delete to automatically clean up the leftover split transaction entry
                try member.transaction.delete(withDatabase)
            } else {
                let destinationAmount = abs(NSDecimalNumber(string: member.amount).multiplying(by: 100).intValue)
                let sourceAmount = destinationAmount * -1
                
                member.transaction.status = status
                member.transaction.entryDate = date
                member.transaction.accountID = selectedAccount!.id!
                
                member.transaction.amount = (type == .Deposit ? destinationAmount : sourceAmount)
                member.transaction.bucketID = member.bucket!.id!
                member.transaction.memo = member.memo
                
                try member.transaction.save(withDatabase)
                
                if member.editStatus == .inMemory {
                    // Create a split transaction record for this new transaction
                    var splitMember = SplitTransaction(id: nil, transactionID: member.transaction.id!, splitHeadTransactionID: headTransaction!.id!, splitUUID: member.splitUUID)
                    try splitMember.save(withDatabase)
                }
            }
        }
        
        if split == nil {
            var splitHead = SplitTransaction(id: nil, transactionID: headTransaction!.id!, splitHeadTransactionID: headTransaction!.id!, splitUUID: splitUUID)
            try splitHead.save(withDatabase)
        }
    }
}

