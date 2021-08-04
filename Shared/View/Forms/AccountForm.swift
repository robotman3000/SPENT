//
//  AccountForm.swift
//  macOS
//
//  Created by Eric Nims on 7/22/21.
//

import SwiftUI

struct AccountForm: View {
    @State var account: Bucket
    
    let onSubmit: (_ data: inout Bucket) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            TextField("Name", text: $account.name)
            
            TextEditor(text: $account.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
        }
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
                        //TODO: Show an alert or some "Invalid Data" indicator
                        print("Account storeState failed!")
                    }
                })
            }
        }).onAppear { loadState() }
        //.frame(minWidth: 300, minHeight: 200)
    }
    
    func loadState(){}
    
    func storeState() -> Bool {
        account.parentID = nil
        account.ancestorID = nil
        account.budgetID = nil
        return true
    }
}


//struct AccountForm_Previews: PreviewProvider {
//    static var previews: some View {
//        AccountForm(onSubmit: {_ in}, onCancel: {})
//    }
//}
