//
//  SplitMemberForm.swift
//  macOS
//
//  Created by Eric Nims on 7/30/21.
//

import SwiftUI

struct SplitMemberForm: View {
    @EnvironmentObject fileprivate var dbStore: DatabaseStore
    
    @State var transaction: Transaction
    @State var bucketChoices: [Bucket]
    
    let splitDirection: Transaction.TransType
    
    @State fileprivate var amount: String = ""
    @State fileprivate var bucket: Bucket?
    
    let onSubmit: (_ data: inout Transaction) -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            HStack{
                Text("$") // TODO: Localize this text
                TextField("Amount", text: $amount)
            }

            BucketPicker(label: "Bucket", selection: $bucket, choices: bucketChoices)
            Section(){
                TextEditor(text: $transaction.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            }
            
            Section{
                HStack{
                    Button("Cancel", action: {
                        onCancel()
                    })
                    Button("Delete", action: {
                        onDelete()
                    })
                    Spacer()
                    Button("Done", action: {
                        if storeState() {
                            onSubmit(&transaction)
                        } else {
                            //TODO: Show an alert or some "Invalid Data" indicator
                            print("Split storeState failed!")
                        }
                    })
                }
            }
        }.onAppear { loadState() }
        .frame(minWidth: 250, minHeight: 150)
    }
    
    func loadState(){
        amount = NSDecimalNumber(value: transaction.amount).dividing(by: 100).stringValue
        
        if splitDirection == .Deposit && transaction.destID != nil {
            bucket = dbStore.database?.resolveOne(transaction.destination)
        }
        
        if splitDirection == .Withdrawal && transaction.sourceID != nil {
            bucket = dbStore.database?.resolveOne(transaction.source)
        }
    }
    
    func storeState() -> Bool {
        transaction.amount = NSDecimalNumber(string: amount).multiplying(by: 100).intValue
        
        if splitDirection == .Deposit {
            transaction.destID = bucket!.id!
        }
        
        if splitDirection == .Withdrawal {
            transaction.sourceID = bucket!.id!
        }
        
        return true
    }
}

//struct SplitMemberForm_Previews: PreviewProvider {
//    static var previews: some View {
//        SplitMemberForm()
//    }
//}
