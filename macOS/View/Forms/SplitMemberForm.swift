//
//  SplitMemberForm.swift
//  macOS
//
//  Created by Eric Nims on 7/30/21.
//

import SwiftUI
import SwiftUIKit
import GRDB

struct SplitMemberForm: View {
    @State var model: SplitMemberFormModel
    let choices: [Bucket]
    
    let onSubmit: (_ model: SplitMemberFormModel) -> Void
    let onDelete: (_ model: SplitMemberFormModel) -> Void
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

//struct SplitMemberForm_Previews: PreviewProvider {
//    static var previews: some View {
//        SplitMemberForm()
//    }
//}
