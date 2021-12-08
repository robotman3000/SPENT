//
//  BucketEditForm.swift
//  iOS
//
//  Created by Eric Nims on 4/21/21.
//

import SwiftUI
import SwiftUIKit

struct BucketForm: View {
    @StateObject var model: BucketFormModel
    
    let onSubmit: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            TextField("Name", text: $model.name)
            
            // Disable changing the bucket parent after creation
            BucketPicker(label: "Account", selection: $model.parent, choices: model.parentChoices).disabled(!model.isNew())
            Toggle("Favorite", isOn: $model.isFavorite)
            TextEditor(text: $model.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
        }.frame(minWidth: 250, minHeight: 250)
        .formFooter(model, onSubmit: onSubmit, onCancel: onCancel)
    }
}

class BucketFormModel: FormModel {
    fileprivate var bucket: Bucket
    
    @Published var name: String
    @Published var isFavorite: Bool
    @Published var memo: String
    
    @Published var parent: Bucket?
    @Published var parentChoices: [Bucket] = []
    
    init(bucket: Bucket, parent: Bucket? = nil){
        self.bucket = bucket
        self.name = bucket.name
        self.isFavorite = bucket.isFavorite
        self.memo = bucket.memo
        self.parent = parent
    }
    
    func loadState(withDatabase: DatabaseStore) throws {
        // TODO: Correctly handle parent from init
        parentChoices = withDatabase.database?.resolve(Bucket.all().filterAccounts()) ?? []
        
        if bucket.parentID != nil {
            parent = withDatabase.database?.resolveOne(bucket.parent)
        }
    }
    
    func validate() throws {
        if name.isEmpty || parent == nil {
            throw FormValidationError("Please provide a name and parent")
        }
    }
    
    func submit(withDatabase: DatabaseStore) throws {
        bucket.name = name
        bucket.parentID = parent?.id
        if let ancestor = parent?.ancestorID {
            bucket.ancestorID = ancestor
        } else {
            bucket.ancestorID = bucket.parentID
        }
        bucket.memo = memo
        bucket.isFavorite = isFavorite
        try withDatabase.updateBucket(&bucket, onComplete: { print("Submit complete") })
    }
    
    func isNew() -> Bool {
        return bucket.id == nil
    }
}
