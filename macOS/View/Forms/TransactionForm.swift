//
//  TransactionForm.swift
//  macOS
//
//  Created by Eric Nims on 6/9/21.
//

import SwiftUI
import SwiftUIKit

struct TransactionForm: View {
    @StateObject var model: TransactionFormModel

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

            Section(header:
                        EnumPicker(label: "Type", selection: $model.type, enumCases: [.Deposit, .Withdrawal]).pickerStyle(SegmentedPickerStyle())
            ){

                BucketPicker(label: model.type == .Withdrawal ? "From" : "To", selection: $model.selectedBucket, choices: model.bucketChoices)
            }

            Section(){
                TextField("Payee", text: $model.payee)
                TextEditor(text: $model.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            }

        }.frame(minWidth: 250, minHeight: 300)
        .formFooter(model, onSubmit: onSubmit, onCancel: onCancel)
    }
}

class TransactionFormModel: FormModel {
    fileprivate var transaction: Transaction
    
    @Published var status: Transaction.StatusTypes
    @Published var date: Date
    @Published var sourceDate: Date
    @Published var destDate: Date
    @Published var sourceID: Int64?
    @Published var destID: Int64?
    @Published var amount: String
    @Published var type: Transaction.TransType
    @Published var payee: String
    @Published var memo: String
    
    @Published var selectedBucket: Bucket?
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
        
        payee = transaction.payee ?? ""
        
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
                selectedBucket = withDatabase.database?.resolveOne(transaction.source)
            }

            if transaction.destID != nil {
                selectedBucket = withDatabase.database?.resolveOne(transaction.destination)
            }
        }

        bucketChoices = withDatabase.database?.resolve(Bucket.all()) ?? []
    }
    
    func validate() throws {
        if amount.isEmpty || selectedBucket == nil {
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

        if type == .Deposit {
            transaction.sourceID = nil
            transaction.destID = selectedBucket?.id
        }

        if type == .Withdrawal {
            transaction.sourceID = selectedBucket?.id
            transaction.destID = nil
        }

        if payee.isEmpty {
            transaction.payee = nil
        } else {
            transaction.payee = payee
        }

        transaction.amount = NSDecimalNumber(string: amount).multiplying(by: 100).intValue


        try withDatabase.updateTransaction(&transaction, onComplete: { print("Submit complete") })
    }
}

//struct TransactionForm_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionForm()
//    }
//}
