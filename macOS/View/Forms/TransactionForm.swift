//
//  TransactionForm.swift
//  macOS
//
//  Created by Eric Nims on 6/9/21.
//

import SwiftUI
import SwiftUIKit
import GRDB

struct TransactionForm: View {
    @StateObject var model: TransactionFormModel

    let onSubmit: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            Section(){
                EnumPicker(label: "Status", selection: $model.status, enumCases: Transaction.StatusTypes.allCases)

                DatePicker("Date", selection: $model.entryDate, displayedComponents: [.date])
                if model.status.rawValue >= Transaction.StatusTypes.Complete.rawValue {
                    DatePicker("Posting Date", selection: $model.postDate, displayedComponents: [.date])
                }

                HStack{
                    Text("Amount $")
                    TextField("", text: $model.amount)
                }
            }

            Section(header:
                        EnumPicker(label: "Type", selection: $model.type, enumCases: [.Deposit, .Withdrawal]).pickerStyle(SegmentedPickerStyle())
            ){

                HStack {
                    BucketPicker(label: "Bucket", selection: $model.selectedBucket, choices: model.bucketChoices)
                    Button("X"){
                        model.selectedBucket = nil
                    }
                }
                AccountPicker(label: model.type == .Withdrawal ? "From" : "To", selection: $model.selectedAccount, choices: model.accountChoices)
            }

            Section(){
                TextField("Payee", text: $model.payee)
                TextEditor(text: $model.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            }

        }
        #if os(macOS)
        .frame(minWidth: 250, minHeight: 300)
        #endif
        .formFooter(model, onSubmit: onSubmit, onCancel: onCancel)
    }
}

//struct TransactionForm_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionForm()
//    }
//}
