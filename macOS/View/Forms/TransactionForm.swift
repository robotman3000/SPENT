//
//  TransactionForm.swift
//  macOS
//
//  Created by Eric Nims on 6/9/21.
//

import SwiftUI
import SwiftUIKit

struct TransactionForm: View {
    @StateObject fileprivate var aContext: AlertContext = AlertContext()
    @EnvironmentObject fileprivate var dbStore: DatabaseStore
    @State var transaction: Transaction
    
    @State var selectedBucket: Bucket?
    @State var bucketChoices: [Bucket]
    
    @State fileprivate var postDate: Date = Date()
    @State fileprivate var payee: String = ""
    @State fileprivate var transType: Transaction.TransType = .Withdrawal
    @State fileprivate var amount: String = ""
    
    let onSubmit: (_ data: inout Transaction) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            EnumPicker(label: "Status", selection: $transaction.status, enumCases: Transaction.StatusTypes.allCases)
            
            Section(){
                DatePicker("Date", selection: $transaction.date, displayedComponents: [.date])
                if transaction.status.rawValue >= Transaction.StatusTypes.Complete.rawValue {
                    DatePicker("Posting Date", selection: $postDate, displayedComponents: [.date])
                }
            }

            HStack{
                Text("$") // TODO: Localize this text
                TextField("Amount", text: $amount)
            }

            Section(header:
                        EnumPicker(label: "Type", selection: $transType, enumCases: [.Deposit, .Withdrawal]).pickerStyle(SegmentedPickerStyle())
            ){

                BucketPicker(label: transType == .Withdrawal ? "From" : "To", selection: $selectedBucket, choices: bucketChoices)
            }
            
            Section(){
                TextField("Payee", text: $payee)
                TextEditor(text: $transaction.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            }
            
        }.onAppear { loadState() }
        .toolbar(content: {
            ToolbarItem(placement: .confirmationAction){
                Button("Done", action: {
                    if storeState() {
                        onSubmit(&transaction)
                    } else {
                        aContext.present(AlertKeys.message(message: "Invalid Input"))
                    }
                })
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: {
                    onCancel()
                })
            }
        }).frame(minWidth: 250, minHeight: 350)
        .alert(context: aContext)
    }
    
    func loadState(){
        payee = transaction.payee ?? ""
        
        if transaction.id != nil {
            // We have an existing transaction
            transType = transaction.type
            
            amount = NSDecimalNumber(value: transaction.amount).dividing(by: 100).stringValue
            
            if transaction.posted != nil {
                postDate = transaction.posted!
            }
            
            if transaction.sourceID != nil {
                selectedBucket = dbStore.database?.resolveOne(transaction.source)
            }
            
            if transaction.destID != nil {
                selectedBucket = dbStore.database?.resolveOne(transaction.destination)
            }
        }
    }
    
    func storeState() -> Bool {
        if amount.isEmpty || selectedBucket == nil {
            return false
        }
        
        if transaction.status.rawValue >= Transaction.StatusTypes.Complete.rawValue {
            transaction.posted = postDate
        }
        
        switch transType {
        case .Deposit:
            transaction.sourceID = nil
            transaction.destID = selectedBucket?.id
        case .Withdrawal:
            transaction.sourceID = selectedBucket?.id
            transaction.destID = nil
        case .Transfer:
            print("Make the compiler happy")
        case .Split:
            print("Make the compiler happy")
        }
        
        if payee.isEmpty {
            transaction.payee = nil
        } else {
            transaction.payee = payee
        }
        
        transaction.amount = NSDecimalNumber(string: amount).multiplying(by: 100).intValue
        
        return true
    }
}

//struct TransactionForm_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionForm()
//    }
//}