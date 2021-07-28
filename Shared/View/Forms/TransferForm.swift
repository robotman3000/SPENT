//
//  TransferForm.swift
//  macOS
//
//  Created by Eric Nims on 7/22/21.
//

import SwiftUI
import SwiftUIKit

struct TransferForm: View {
    @EnvironmentObject var dbStore: DatabaseStore
    @StateObject var aContext = AlertContext()
    @State var transaction: Transaction = Transaction(id: nil, status: .Uninitiated, date: Date(), amount: 0)
    let currentBucket: Bucket
    
    @State var postDate: Date = Date()
    @StateObject var selectedSource: ObservableStructWrapper<Bucket> = ObservableStructWrapper<Bucket>()
    @StateObject var selectedDest: ObservableStructWrapper<Bucket> = ObservableStructWrapper<Bucket>()
    @State var amount: String = ""
    @State var groupString: String = ""
    
    var hiddenFormatter: NumberFormatter = NumberFormatter()
    var formatter: NumberFormatter {
        get {
            //formatter.usesGroupingSeparator = true
            hiddenFormatter.numberStyle = .currency
            // localize to your grouping and decimal separator
            hiddenFormatter.locale = Locale.current
            //formatter.maximumFractionDigits = 2
            return hiddenFormatter
        }
    }
    
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

            //TextField("Amount", value: $amount, formatter: formatter)
            HStack{
                Text("$") // TODO: Localize this text
                TextField("Amount", text: $amount)
            }

            BucketPicker(label: "From", selection: $selectedSource.wrappedStruct, choices: dbStore.buckets)
            BucketPicker(label: "To", selection: $selectedDest.wrappedStruct, choices: dbStore.buckets)
            
            Section(){
                TextEditor(text: $transaction.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            }
            
            Section(){
                Button("Generate ID"){
                    groupString = UUID().uuidString
                }
                TextField("Group", text: $groupString)
            }
            
        }.onAppear { loadState() }
        .toolbar(content: {
            ToolbarItem(placement: .confirmationAction){
                Button("Done", action: {
                    if storeState() {
                        onSubmit(&transaction)
                    } else {
                        aContext.present(UIAlerts.message(message: "Form validation failed"))
                        print("Transfer storeState failed!")
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
        if transaction.id == nil {
            selectedSource.wrappedStruct = currentBucket
            //selectedDest.wrappedStruct = currentBucket
        } else {
            // We have an existing transaction
            groupString = transaction.group?.uuidString ?? ""
            amount = NSDecimalNumber(value: transaction.amount).dividing(by: 100).stringValue
            
            if transaction.posted != nil {
                postDate = transaction.posted!
            }
            
            if transaction.sourceID != nil {
                selectedSource.wrappedStruct = dbStore.database?.resolveOne(transaction.source)
            }
            
            if transaction.destID != nil {
                selectedDest.wrappedStruct = dbStore.database?.resolveOne(transaction.destination)
            }
        }
    }
    
    func storeState() -> Bool {
        if transaction.status.rawValue >= Transaction.StatusTypes.Complete.rawValue {
            transaction.posted = postDate
        }
        
        if selectedSource.wrappedStruct?.id == selectedDest.wrappedStruct?.id {
            return false
        }
        
        if selectedSource.wrappedStruct?.id == nil || selectedDest.wrappedStruct?.id == nil {
            return false
        }
        
        transaction.sourceID = selectedSource.wrappedStruct?.id
        transaction.destID = selectedDest.wrappedStruct?.id
        
        transaction.payee = nil // Transfers don't need payees
        transaction.group = UUID(uuidString: groupString)
        transaction.amount = NSDecimalNumber(string: amount).multiplying(by: 100).intValue
        
        return true
    }
}
