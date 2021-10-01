//
//  BucketEditForm.swift
//  iOS
//
//  Created by Eric Nims on 4/21/21.
//

import SwiftUI
import SwiftUIKit

struct BucketForm: View {
    @StateObject fileprivate var aContext: AlertContext = AlertContext()
    @EnvironmentObject fileprivate var dbStore: DatabaseStore
    @State var bucket: Bucket
    
    @State var parent: Bucket?
    @State fileprivate var hasBudget = false
    @State fileprivate var budget: Schedule?
    
    @Query(AccountRequest()) var parentChoices: [Bucket]
    
    let onSubmit: (_ data: inout Bucket) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            TextField("Name", text: $bucket.name)
            
            // Disable changing the bucket parent after creation
            // TODO: Make this possible in the future
            BucketPicker(label: "Account", selection: $parent, choices: parentChoices).disabled(bucket.id != nil)
            
            TextEditor(text: $bucket.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
        }.frame(minWidth: 250, minHeight: 250)
        .toolbar(content: {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: {
                    onCancel()
                })
            }
            ToolbarItem(placement: .confirmationAction){
                Button("Done", action: {
                    if storeState() {
                        onSubmit(&bucket)
                    } else {
                        aContext.present(AlertKeys.message(message: "Invalid input"))
                    }
                })
            }
        }).onAppear { loadState() }
        .alert(context: aContext)
    }
    
    func loadState(){
        if bucket.parentID != nil {
            parent = dbStore.database?.resolveOne(bucket.parent)
        }
    }
    
    func storeState() -> Bool {
        if bucket.name.isEmpty || parent == nil {
            return false
        }
        
        if hasBudget && budget == nil {
            return false
        }
        
        bucket.parentID = parent?.id
        if let ancestor = parent?.ancestorID {
            bucket.ancestorID = ancestor
        } else {
            bucket.ancestorID = bucket.parentID
        }
        return true
    }
}
