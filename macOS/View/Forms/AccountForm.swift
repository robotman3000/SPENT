//
//  AccountForm.swift
//  macOS
//
//  Created by Eric Nims on 7/22/21.
//

import SwiftUI
import SwiftUIKit
import GRDB

struct AccountForm: View {
    @StateObject var model: AccountFormModel
    
    let onSubmit: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        // Form Controls
        Form {
            TextField("Name", text: $model.name)
//            Toggle("Favorite", isOn: $model.isFavorite)
//            TextEditor(text: $model.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
        }.frame(minWidth: 250, minHeight: 200)
        
        // Form Lifecycle
        .formFooter(model, onSubmit: onSubmit, onCancel: onCancel)
    }
}

class AccountFormModel: FormModel {
    fileprivate var account: Account
    
    @Published var name: String
    
    init(_ account: Account){
        self.account = account
        self.name = account.name
    }
    
    func loadState(withDatabase: Database) throws {}
    
    func validate() throws {
        if name.isEmpty {
            throw FormValidationError("Please provide a name")
        }
    }
    
    func submit(withDatabase: Database) throws {
        account.name = name
        try account.save(withDatabase)
    }
}

//struct AccountForm_Previews: PreviewProvider {
//    static var previews: some View {
//        AccountForm(onSubmit: {_ in}, onCancel: {})
//    }
//}
