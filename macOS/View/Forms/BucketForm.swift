//
//  BucketEditForm.swift
//  iOS
//
//  Created by Eric Nims on 4/21/21.
//

import SwiftUI
import SwiftUIKit
import GRDB

struct BucketForm: View {
    @StateObject var model: BucketFormModel
    
    let onSubmit: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            TextField("Name", text: $model.name)
            TextField("Category", text: $model.category)
        }.frame(minWidth: 250, minHeight: 60)
        .formFooter(model, onSubmit: onSubmit, onCancel: onCancel)
    }
}
