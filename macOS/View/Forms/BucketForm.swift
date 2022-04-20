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

class BucketFormModel: FormModel {
    fileprivate var bucket: Bucket
    
    @Published var name: String
    @Published var category: String
    
    init(bucket: Bucket){
        self.bucket = bucket
        self.name = bucket.name
        self.category = bucket.category
    }
    
    func loadState(withDatabase: Database) throws {}
    
    func validate() throws {
        if name.isEmpty {
            throw FormValidationError("Please provide a name")
        }
    }
    
    func submit(withDatabase: Database) throws {
        bucket.name = name
        bucket.category = category
        try bucket.save(withDatabase)
    }
}
