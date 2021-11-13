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
                    DatePicker("Source Posting Date", selection: $model.sourceDate, displayedComponents: [.date])
                    DatePicker("Destination Posting Date", selection: $model.destDate, displayedComponents: [.date])
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
    
    @Published var status: Transaction.StatusTypes
    @Published var date: Date
    @Published var sourceDate: Date
    @Published var destDate: Date
    @Published var sourceID: Int64?
    @Published var destID: Int64?
    @Published var amount: String
    @Published var type: Transaction.TransType
    @Published var memo: String
    
    @Published var selectedSource: Bucket?
    @Published var selectedDest: Bucket?
    @Published var bucketChoices: [Bucket]
   
    init(transaction: Transaction, contextBucket: Int64? = nil){
        // TODO: Use contextBucket to preselect source/dest
        amount = ""
        type = .Withdrawal
        bucketChoices = []
        self.transaction = transaction
        self.status = transaction.status
        self.date = transaction.date
        self.memo = transaction.memo
        
        sourceDate = Date()
        destDate = Date()
        
        if transaction.id != nil {
            // We have an existing transaction
            type = transaction.type
            
            amount = NSDecimalNumber(value: transaction.amount).dividing(by: 100).stringValue
            
            if transaction.sourcePosted != nil {
                sourceDate = transaction.sourcePosted!
            }
            if transaction.destPosted != nil {
                destDate = transaction.destPosted!
            }
        }
    }
    
    func loadState(withDatabase: DatabaseStore) throws {
        if transaction.id != nil {
            if transaction.sourceID != nil {
                selectedSource = withDatabase.database?.resolveOne(transaction.source)
            }

            if transaction.destID != nil {
                selectedDest = withDatabase.database?.resolveOne(transaction.destination)
            }
        }

        bucketChoices = withDatabase.database?.resolve(Bucket.all()) ?? []
    }
    
    func validate() throws {
        if selectedSource?.id == selectedDest?.id {
            throw FormValidationError()
        }
        
        if selectedSource?.id == nil || selectedDest?.id == nil {
            throw FormValidationError()
        }
        
        if amount.isEmpty {
            throw FormValidationError()
        }

        if status.rawValue >= Transaction.StatusTypes.Complete.rawValue {
            if sourceDate < date || destDate < date {
                // Prevent a transaction that posted before it was made
                throw FormValidationError()
            }
        }
    }
    
    func submit(withDatabase: DatabaseStore) throws {
        if status.rawValue >= Transaction.StatusTypes.Complete.rawValue {
            transaction.sourcePosted = sourceDate
            transaction.destPosted = destDate
        } else {
            transaction.sourcePosted = nil
            transaction.destPosted = nil
        }

        transaction.sourceID = selectedSource?.id
        transaction.destID = selectedDest?.id
        transaction.payee = nil // Transfers don't need payees
        transaction.amount = NSDecimalNumber(string: amount).multiplying(by: 100).intValue

        try withDatabase.updateTransaction(&transaction, onComplete: { print("Submit complete") })
    }
}
