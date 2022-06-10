//
//  TemplateForm.swift
//  macOS
//
//  Created by Eric Nims on 10/5/21.
//

import SwiftUI
import SwiftUIKit
import GRDB

struct TemplateForm: View {
    @StateObject var model: TemplateFormModel
    
    let onSubmit: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            TextField("Name", text: $model.name)
            
            HStack{
                Text("$") // TODO: Localize this text
                TextField("Amount", text: $model.amount)
            }

            Section(header:
                        EnumPicker(label: "Type", selection: $model.type, enumCases: [.Deposit, .Withdrawal]).pickerStyle(SegmentedPickerStyle())
            ){

                HStack {
                    BucketPicker(label: "Bucket", selection: $model.bucket, choices: model.bucketChoices)
                    Button("X"){
                        model.bucket = nil
                    }
                }
                AccountPicker(label: model.type == .Withdrawal ? "From" : "To", selection: $model.account, choices: model.accountChoices)
            }
            
            Section(){
                TextField("Payee", text: $model.payee)
                TextEditor(text: $model.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            }
            
        }.frame(minWidth: 250, minHeight: 300)
        .formFooter(model, onSubmit: onSubmit, onCancel: onCancel)
    }
}

//struct TemplateForm_Previews: PreviewProvider {
//    static var previews: some View {
//        TemplateForm()
//    }
//}
