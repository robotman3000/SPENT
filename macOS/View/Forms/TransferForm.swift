//
//  TransferForm.swift
//  macOS
//
//  Created by Eric Nims on 7/22/21.
//

import SwiftUI
import SwiftUIKit

struct TransferForm: View {
    @StateObject var model: TransferFormModel
    
    let onSubmit: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            EnumPicker(label: "Status", selection: $model.status, enumCases: Transaction.StatusTypes.allCases)
            
            Section(){
                DatePicker("Date", selection: $model.date, displayedComponents: [.date])
                if model.status.rawValue >= Transaction.StatusTypes.Complete.rawValue {
                    DatePicker("Posting Date", selection: $model.postDate, displayedComponents: [.date])
                }
            }
            
            HStack{
                Text("$") // TODO: Localize this text
                TextField("Amount", text: $model.amount)
            }

            BucketPicker(label: "From", selection: $model.selectedSource, choices: model.bucketChoices)
            BucketPicker(label: "To", selection: $model.selectedDest, choices: model.bucketChoices)
            
            Section(){
                TextEditor(text: $model.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            }
        }.frame(minWidth: 250, minHeight: 300)
        .formFooter(model, onSubmit: onSubmit, onCancel: onCancel)
    }
}

class TransferFormModel: FormModel {
    fileprivate var transaction: Transaction
    
    fileprivate var contextType: Transaction.TransType = .Withdrawal
    
    @Published var status: Transaction.StatusTypes
    @Published var date: Date
    @Published var postDate: Date
    @Published var sourceID: Int64?
    @Published var destID: Int64?
    @Published var amount: String
    @Published var type: Transaction.TransType
    @Published var memo: String
    
    @Published var selectedSource: Bucket?
    @Published var selectedDest: Bucket?
    @Published var bucketChoices: [Bucket]
   
    fileprivate let contextBucketID: Int64?
    
    init(transaction: Transaction, contextBucket: Int64? = nil){
        amount = ""
        type = .Withdrawal
        bucketChoices = []
        self.transaction = transaction
        self.status = transaction.status
        self.date = transaction.date
        self.memo = transaction.memo
        
        postDate = Date()
        
        if transaction.id != nil {
            // We have an existing transaction
            type = transaction.type
            
            amount = NSDecimalNumber(value: transaction.amount).dividing(by: 100).stringValue
            contextType = transaction.type
            if let bucketID = contextBucket {
                print("Transfer Form: Using context bucket")
                contextType = transaction.getType(convertTransfer: true, bucket: bucketID)
            }
            
            if contextType == .Deposit && transaction.destPosted != nil {
                postDate = transaction.destPosted!
            }
            
            if contextType == .Withdrawal && transaction.sourcePosted != nil {
                postDate = transaction.sourcePosted!
            }
        }
        
        self.contextBucketID = contextBucket
    }
    
    func loadState(withDatabase: DatabaseStore) throws {
        if transaction.id != nil {
            if transaction.sourceID != nil {
                selectedSource = withDatabase.database?.resolveOne(transaction.source)
            }

            if transaction.destID != nil {
                selectedDest = withDatabase.database?.resolveOne(transaction.destination)
            }
        } else {
            if let id = contextBucketID {
                selectedSource = withDatabase.database?.resolveOne(Bucket.filter(id: id))
            }
        }

        bucketChoices = withDatabase.database?.resolve(Bucket.all()) ?? []
    }
    
    func validate() throws {
        if selectedSource?.id == selectedDest?.id {
            throw FormValidationError("The from and to fields must be different")
        }
        
        if selectedSource?.id == nil || selectedDest?.id == nil {
            throw FormValidationError("Please provide a value for the From and To fields")
        }
        
        if amount.isEmpty {
            throw FormValidationError("Please provide a valid amount")
        }

        if status.rawValue >= Transaction.StatusTypes.Complete.rawValue {
            if postDate < date {
                // Prevent a transaction that posted before it was made
                throw FormValidationError("A transfer cannot have a post date before it's creation date")
            }
        }
    }
    
    func submit(withDatabase: DatabaseStore) throws {
        transaction.status = status
        transaction.date = date
        if status.rawValue >= Transaction.StatusTypes.Complete.rawValue {
            // If either is null then set them both
            // otherwise update based on type
            if (transaction.sourcePosted == nil || transaction.destPosted == nil) {
                transaction.sourcePosted = postDate
                transaction.destPosted = postDate
            } else {
                if contextType == .Deposit {
                    transaction.destPosted = postDate
                }
                
                if contextType == .Withdrawal {
                    transaction.sourcePosted = postDate
                }
            }
        } else {
            transaction.sourcePosted = nil
            transaction.destPosted = nil
        }

        transaction.sourceID = selectedSource?.id
        transaction.destID = selectedDest?.id
        transaction.payee = nil // Transfers don't need payees
        transaction.memo = memo
        transaction.amount = NSDecimalNumber(string: amount).multiplying(by: 100).intValue

        try withDatabase.write { db in
            try withDatabase.saveTransaction(db, &transaction)
        }
    }
}
