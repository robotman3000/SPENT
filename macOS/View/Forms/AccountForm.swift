//
//  AccountForm.swift
//  macOS
//
//  Created by Eric Nims on 7/22/21.
//

import SwiftUI
import SwiftUIKit

struct AccountForm: View {
    @StateObject fileprivate var aContext: AlertContext = AlertContext()
    @State var account: Bucket
    
    let onSubmit: (_ data: inout Bucket) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            TextField("Name", text: $account.name)
            
            TextEditor(text: $account.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
        }.frame(minWidth: 250, minHeight: 200)
        .toolbar(content: {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: {
                    onCancel()
                })
            }
            ToolbarItem(placement: .confirmationAction){
                Button("Done", action: {
                    if storeState() {
                        onSubmit(&account)
                    } else {
                        aContext.present(AlertKeys.message(message: "Invalid input"))
                    }
                })
            }
        }).onAppear { loadState() }
        .alert(context: aContext)
    }
    
    func loadState(){}
    
    func storeState() -> Bool {
        if account.name.isEmpty {
            return false
        }
        
        account.parentID = nil
        account.ancestorID = nil
        return true
    }
}


//struct AccountForm_Previews: PreviewProvider {
//    static var previews: some View {
//        AccountForm(onSubmit: {_ in}, onCancel: {})
//    }
//}
