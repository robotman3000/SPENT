//
//  TagEditForm.swift
//  iOS
//
//  Created by Eric Nims on 4/21/21.
//

import SwiftUI
import SwiftUIKit

struct TagForm: View {
    @StateObject var model: TagFormModel
    
    let onSubmit: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            Section(){
                TextField("Name", text: $model.name)
                Toggle("Favorite", isOn: $model.isFavorite)
                TextEditor(text: $model.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            }
        }.frame(minWidth: 250, minHeight: 200)
        .formFooter(model, onSubmit: onSubmit, onCancel: onCancel)
    }
}

class TagFormModel: FormModel {
    fileprivate var tag: Tag
    
    @Published var name: String
    @Published var isFavorite: Bool
    @Published var memo: String
    
    init(tag: Tag){
        self.tag = tag
        self.name = tag.name
        self.isFavorite = tag.isFavorite
        self.memo = tag.memo
    }
    
    func loadState(withDatabase: DatabaseStore) throws {}
    
    func validate() throws {
        if name.isEmpty {
            throw FormValidationError("Please provide a name")
        }
    }
    
    func submit(withDatabase: DatabaseStore) throws {
        tag.name = name
        tag.isFavorite = isFavorite
        tag.memo = memo
        try withDatabase.write({ db in
            try withDatabase.saveTag(db, &tag)
        })
    }
    
    func isNew() -> Bool {
        return tag.id == nil
    }
}
