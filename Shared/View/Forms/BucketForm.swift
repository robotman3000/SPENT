//
//  BucketEditForm.swift
//  iOS
//
//  Created by Eric Nims on 4/21/21.
//

import SwiftUI

struct BucketForm: View {
    @EnvironmentObject fileprivate var dbStore: DatabaseStore
    @State var bucket: Bucket
    
    @State var parent: Bucket?
    @State fileprivate var hasBudget = false
    @State fileprivate var budget: Schedule?
    
    let parentChoices: [Bucket]
    let budgetChoices: [Schedule]
    
    let onSubmit: (_ data: inout Bucket) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            TextField("Name", text: $bucket.name)
            
            // Disable changing the bucket parent after creation
            // TODO: Make this possible in the future
            BucketPicker(label: "Account", selection: $parent, choices: parentChoices).disabled(bucket.id != nil)
            
            Section(){
                Toggle("Enable Budget", isOn: $hasBudget)
                SchedulePicker(label: "Budget", selection: $budget, choices: budgetChoices)
                    .disabled(!hasBudget)
            }
            
            TextEditor(text: $bucket.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
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
                        onSubmit(&bucket)
                    } else {
                        //TODO: Show an alert or some "Invalid Data" indicator
                        print("Bucket storeState failed!")
                    }
                })
            }
        }).onAppear { loadState() }
        .frame(minWidth: 300, minHeight: 200)
    }
    
    func loadState(){
        if bucket.parentID != nil {
            parent = dbStore.database?.resolveOne(bucket.parent)
        }
        
        if bucket.budgetID == nil {
            hasBudget = false
        } else {
            budget = dbStore.database?.resolveOne(bucket.budget)
        }
    }
    
    func storeState() -> Bool {
        bucket.parentID = parent?.id
        if let ancestor = parent?.ancestorID {
            bucket.ancestorID = ancestor
        } else {
            bucket.ancestorID = bucket.parentID
        }
        
        if hasBudget {
            bucket.budgetID = nil
        } else {
            bucket.budgetID = budget?.id
        }
        return true
    }
}
