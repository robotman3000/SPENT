//
//  AccountForm.swift
//  macOS
//
//  Created by Eric Nims on 7/22/21.
//

import SwiftUI
import SwiftUIKit

struct AccountForm: View {
    @StateObject var model: AccountFormModel
    
    let onSubmit: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        // Form Controls
        Form {
            TextField("Name", text: $model.name)
            Toggle("Favorite", isOn: $model.isFavorite)
            TextEditor(text: $model.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
        }.frame(minWidth: 250, minHeight: 200)
        
        // Form Lifecycle
        .formFooter(model, onSubmit: onSubmit, onCancel: onCancel)
    }
}

class AccountFormModel: FormModel {
    fileprivate var bucket: Bucket
    
    @Published var name: String
    @Published var isFavorite: Bool
    @Published var memo: String
    
    init(bucket: Bucket){
        self.bucket = bucket
        self.name = bucket.name
        self.isFavorite = bucket.isFavorite
        self.memo = bucket.memo
    }
    
    func loadState(withDatabase: DatabaseStore) throws {}
    
    func validate() throws {
        if name.isEmpty {
            throw FormValidationError("Please provide a name")
        }
    }
    
    func submit(withDatabase: DatabaseStore) throws {
        bucket.name = name
        bucket.parentID = nil
        bucket.ancestorID = nil
        bucket.memo = memo
        bucket.isFavorite = isFavorite
        try withDatabase.write { db in
            try withDatabase.saveBucket(db, &bucket)
        }
    }
}

//struct AccountForm_Previews: PreviewProvider {
//    static var previews: some View {
//        AccountForm(onSubmit: {_ in}, onCancel: {})
//    }
//}
