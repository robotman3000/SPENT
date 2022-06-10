//
//  TransferForm.swift
//  macOS
//
//  Created by Eric Nims on 7/22/21.
//

import SwiftUI
import SwiftUIKit
import GRDB

struct TransferForm: View {
    @StateObject var model: TransferFormModel
    
    let onSubmit: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            EnumPicker(label: "Status", selection: $model.status, enumCases: Transaction.StatusTypes.allCases)
            
            Section(){
                DatePicker("Date", selection: $model.entryDate, displayedComponents: [.date])
                if model.status.rawValue >= Transaction.StatusTypes.Complete.rawValue {
                    DatePicker("Posting Date", selection: $model.postDate, displayedComponents: [.date])
                }
            }
            
            HStack{
                Text("$") // TODO: Localize this text
                TextField("Amount", text: $model.amount)
            }

            AccountPicker(label: "From", selection: $model.sourceAccount, choices: model.accountChoices)
            AccountPicker(label: "To", selection: $model.destinationAccount, choices: model.accountChoices)
            
            Section(){
                TextEditor(text: $model.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            }
        }.frame(minWidth: 250, minHeight: 300)
        .formFooter(model, onSubmit: onSubmit, onCancel: onCancel)
    }
}
