//
//  TransferForm.swift
//  macOS
//
//  Created by Eric Nims on 7/22/21.
//

import SwiftUI
import SwiftUIKit

struct TransferForm: View {
    @EnvironmentObject fileprivate var dbStore: DatabaseStore
    @StateObject fileprivate var aContext = AlertContext()
    @State var transaction: Transaction
    
    @Query(BucketRequest()) var bucketChoices: [Bucket]
    
    @State fileprivate var postDate: Date = Date()
    @State var selectedSource: Bucket?
    @State var selectedDest: Bucket?
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

            BucketPicker(label: "From", selection: $selectedSource, choices: bucketChoices)
            BucketPicker(label: "To", selection: $selectedDest, choices: bucketChoices)
            
            Section(){
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
        }).frame(minWidth: 250, minHeight: 325).alert(context: aContext)
    }
    
    func loadState(){
        // If we have a new transaction
        if transaction.id != nil {
            // We have an existing transaction
            amount = NSDecimalNumber(value: transaction.amount).dividing(by: 100).stringValue
            
            if transaction.posted != nil {
                postDate = transaction.posted!
            }
            
            if transaction.sourceID != nil {
                selectedSource = dbStore.database?.resolveOne(transaction.source)
            }
            
            if transaction.destID != nil {
                selectedDest = dbStore.database?.resolveOne(transaction.destination)
            }
        }
    }
    
    func storeState() -> Bool {
        if selectedSource?.id == selectedDest?.id {
            return false
        }
        
        if selectedSource?.id == nil || selectedDest?.id == nil {
            return false
        }
        
        if amount.isEmpty {
            return false
        }
        
        if transaction.status.rawValue >= Transaction.StatusTypes.Complete.rawValue {
            if postDate < transaction.date {
                // Prevent a transaction that posted before it was made
                return false
            }
            transaction.posted = postDate
        }
        
        transaction.sourceID = selectedSource?.id
        transaction.destID = selectedDest?.id
        
        transaction.payee = nil // Transfers don't need payees
        transaction.amount = NSDecimalNumber(string: amount).multiplying(by: 100).intValue
        
        return true
    }
}
