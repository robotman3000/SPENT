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
            }
        }.frame(minWidth: 250, minHeight: 20)
        .formFooter(model, onSubmit: onSubmit, onCancel: onCancel)
    }
}
