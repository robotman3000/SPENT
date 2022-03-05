//
//  TagEditForm.swift
//  iOS
//
//  Created by Eric Nims on 4/21/21.
//

import SwiftUI
import SwiftUIKit
import GRDB

struct TagForm: View {
    @StateObject var model: TagFormModel
    
    let onSubmit: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            Section(){
                TextField("Name", text: $model.name)
            }
        }.frame(minWidth: 250, minHeight: 200)
        .formFooter(model, onSubmit: onSubmit, onCancel: onCancel)
    }
}

class TagFormModel: FormModel {
    fileprivate var tag: Tag
    
    @Published var name: String
    
    init(tag: Tag){
        self.tag = tag
        self.name = tag.name
    }
    
    func loadState(withDatabase: Database) throws {}
    
    func validate() throws {
        if name.isEmpty {
            throw FormValidationError("Please provide a name")
        }
    }
    
    func submit(withDatabase: Database) throws {
        tag.name = name
        try tag.save(withDatabase)
    }
}
