//
//  TransactionForm.swift
//  macOS
//
//  Created by Eric Nims on 6/9/21.
//

import SwiftUI

import SwiftUI

struct TransactionForm: View {
    let title: String
    @State var transaction: Transaction = Transaction(id: nil, status: .Uninitiated, date: Date(), amount: 0)
    @State var postDate: Date = Date()
    @State var payee: String = ""
    @State var transType: Transaction.TransType = .Deposit
    @State var sourceIndex = 0
    @State var destIndex = 0
    @State var amount: String = ""
    @Query(BucketRequest()) var parentChoices: [Bucket]
    
    
    let onSubmit: (_ data: inout Transaction) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack{
            Form {
                Picker(selection: $transaction.status, label: Text("Status")) {
                    ForEach(Transaction.StatusTypes.allCases) { tStatus in
                        Text(tStatus.getStringName()).tag(tStatus)
                    }
                }
                
                DatePicker("Date", selection: $transaction.date, displayedComponents: [.date])
                DatePicker("Posting Date", selection: $postDate, displayedComponents: [.date]).disabled(transaction.status.rawValue < Transaction.StatusTypes.Complete.rawValue)
                
                TextField("Amount", text: $amount)

                Picker(selection: $transType, label: Text("Type")) {
                    ForEach(Transaction.TransType.allCases) { tType in
                        Text(tType.rawValue).tag(tType)
                    }
                }
                
                VStack() {
                    switch transType {
                    case .Deposit:
                        Picker(selection: $destIndex, label: Text("To")) {
                            ForEach(0 ..< parentChoices.count) {
                                Text(self.parentChoices[$0].name)
                            }
                        }
                    case .Withdrawal:
                        Picker(selection: $sourceIndex, label: Text("From")) {
                            ForEach(0 ..< parentChoices.count) {
                                Text(self.parentChoices[$0].name)
                            }
                        }
                    case .Transfer:
                        Picker(selection: $sourceIndex, label: Text("From")) {
                            ForEach(0 ..< parentChoices.count) {
                                Text(self.parentChoices[$0].name)
                            }
                        }
                        Picker(selection: $destIndex, label: Text("To")) {
                            ForEach(0 ..< parentChoices.count) {
                                Text(self.parentChoices[$0].name)
                            }
                        }
                    }
                }
                
                TextField("Payee", text: $payee)
                TextField("Memo", text: $transaction.memo)

                // tags
                //TextField("Name", text: $tag.name)
                //TextField("Memo", text: $tag.memo)
            }//.navigationTitle(Text(title))
            .onAppear {
                if transaction.posted != nil {
                    postDate = transaction.posted!
                }
                for (index, bucketChoice) in parentChoices.enumerated() {
                    if bucketChoice.id == transaction.destID {
                        destIndex = index
                    }
                    if bucketChoice.id == transaction.sourceID {
                        sourceIndex = index
                    }
                }
                
                transType = transaction.getType()
                
                payee = transaction.payee ?? ""
                
                amount = "\(transaction.amount)"
            }
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction){
                    Button("Done", action: {
                        
                        if transaction.status.rawValue >= Transaction.StatusTypes.Complete.rawValue {
                            transaction.posted = postDate
                        }
                        
                        transaction.sourceID = parentChoices[sourceIndex].id
                        transaction.destID = parentChoices[destIndex].id
                        switch transType {
                        case .Deposit:
                            transaction.sourceID = nil
                        case .Withdrawal:
                            transaction.destID = nil
                        case .Transfer:
                            1+1
                        }
                        
                        if payee.isEmpty {
                            transaction.payee = nil
                        } else {
                            transaction.payee = payee
                        }
                        
                        transaction.amount = Int(amount)!
                        
                        onSubmit(&transaction)
                    })
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: {
                        onCancel()
                    })
                }
            })
        }
    }
}

//struct TransactionForm_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionForm()
//    }
//}
