//
//  TransactionForm.swift
//  macOS
//
//  Created by Eric Nims on 6/9/21.
//

import SwiftUI

struct TransactionForm: View {
    @EnvironmentObject var dbStore: DatabaseStore
    @State var transaction: Transaction = Transaction(id: nil, status: .Uninitiated, date: Date(), amount: 0)
    let currentBucket: Bucket?
    @State var bucketChoices: [Bucket] = []
    @State fileprivate var postDate: Date = Date()
    @State fileprivate var payee: String = ""
    @State fileprivate var transType: Transaction.TransType = .Withdrawal
    @State fileprivate var selectedSource: Bucket?
    //@State var amount: NSDecimalNumber = 0.0
    @State fileprivate var amount: String = ""
    @State fileprivate var groupString: String = ""
    
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

            Section(header:
                        EnumPicker(label: "Type", selection: $transType, enumCases: [.Deposit, .Withdrawal]).pickerStyle(SegmentedPickerStyle())
            ){
                if transType == .Transfer {
                    // This is for use with batch editing once the feature is implemented
                    Text("Alert! Transaction Form was opened using a transfer!")
                    //BucketPicker(label: "From", selection: $selectedSource.wrappedStruct, choices: bucketChoices)
                    //BucketPicker(label: "To", selection: $selectedDest.wrappedStruct, choices: bucketChoices)
                } else {
                    BucketPicker(label: transType == .Withdrawal ? "From" : "To", selection: $selectedSource, choices: bucketChoices)
                }
            }
            
            Section(){
                TextField("Payee", text: $payee)
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
                        //TODO: Show an alert or some "Invalid Data" indicator
                        print("Transaction storeState failed!")
                    }
                })
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: {
                    onCancel()
                })
            }
        }).frame(minWidth: 250, minHeight: 350)
    }
    
    func loadState(){
        // If we have a new transaction
        if transaction.id == nil {
            selectedSource = currentBucket
            //selectedDest.wrappedStruct = currentBucket
        } else {
            // We have an existing transaction
            transType = transaction.type
            payee = transaction.payee ?? ""
            groupString = transaction.group?.uuidString ?? ""
            amount = NSDecimalNumber(value: transaction.amount).dividing(by: 100).stringValue
            
            if transaction.posted != nil {
                postDate = transaction.posted!
            }
            
            if transaction.sourceID != nil {
                selectedSource = dbStore.database?.resolveOne(transaction.source)
            }
            
            if transaction.destID != nil {
                selectedSource = dbStore.database?.resolveOne(transaction.destination)
            }
        }
        
        if bucketChoices.isEmpty {
            // If we weren't provided a list of choices
            if let currentB = currentBucket {
                if currentB.ancestorID == nil {
                    bucketChoices.append(currentB)
                }
                
                bucketChoices.append(contentsOf: dbStore.database?.resolve(currentB.tree) ?? [])
            }
        }
        
    }
    
    func storeState() -> Bool {
        if transaction.status.rawValue >= Transaction.StatusTypes.Complete.rawValue {
            transaction.posted = postDate
        }
        
        
        
        
        switch transType {
        case .Deposit:
            transaction.sourceID = nil
            transaction.destID = selectedSource?.id
        case .Withdrawal:
            transaction.sourceID = selectedSource?.id
            transaction.destID = nil
        case .Transfer:
            print("Make the compiler happy")
        }
        
        if payee.isEmpty {
            transaction.payee = nil
        } else {
            transaction.payee = payee
        }
        
        transaction.group = UUID(uuidString: groupString)
        
        transaction.amount = NSDecimalNumber(string: amount).multiplying(by: 100).intValue
        
        return true
    }
}

//struct TransactionForm_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionForm()
//    }
//}
