//
//  SplitMemberForm.swift
//  macOS
//
//  Created by Eric Nims on 7/30/21.
//

import SwiftUI
import SwiftUIKit

struct SplitMemberForm: View {
    @State var model: SplitMemberModel
    let choices: [Bucket]
    
    let onSubmit: (_ model: SplitMemberModel) -> Void
    let onDelete: (_ model: SplitMemberModel) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            HStack{
                Text("$") // TODO: Localize this text
                TextField("Amount", text: $model.amount)
            }

            BucketPicker(label: "Bucket", selection: $model.bucket, choices: choices)
            Section(){
                TextEditor(text: $model.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            }
            
            Section{
                HStack{
                    Button("Cancel", action: {
                        onCancel()
                    })
                    
                    Button("Delete", action: {
                        onDelete(model)
                    })
                    
                    Spacer()
                    
                    Button("Done", action: {
                        onSubmit(model)
                    })
                }
            }
        }.frame(minWidth: 250, minHeight: 150).padding()
    }
}

struct SplitMemberModel: Identifiable, Hashable {
    var id: UUID = UUID()
    
    let transaction: Transaction?
    var amount: String
    var bucket: Bucket?
    var memo: String
    
    init(transaction: Transaction?, bucket: Bucket?){
        self.transaction = transaction
        self.amount = NSDecimalNumber(value: transaction?.amount ?? 0).dividing(by: 100).stringValue
        self.bucket = bucket
        self.memo = transaction?.memo ?? ""
    }
}

//struct SplitMemberForm_Previews: PreviewProvider {
//    static var previews: some View {
//        SplitMemberForm()
//    }
//}
