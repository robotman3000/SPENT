//
//  BucketEditForm.swift
//  iOS
//
//  Created by Eric Nims on 4/21/21.
//

import SwiftUI

struct BucketForm: View {
    @EnvironmentObject var dbStore: DatabaseStore
    @State var bucket: Bucket = Bucket(id: nil, name: "")
    @State fileprivate var hasBudget = false
    @State var selected: Bucket?
    @State fileprivate var selectedSchedule: Schedule?
    let accountChoices: [Bucket]
    let scheduleChoices: [Schedule]
    
    let onSubmit: (_ data: inout Bucket) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            TextField("Name", text: $bucket.name)
            BucketPicker(label: "Account", selection: $selected, choices: accountChoices)
            
            Section(){
                Toggle("Enable Budget", isOn: $hasBudget)
                SchedulePicker(label: "Budget", selection: $selectedSchedule, choices: scheduleChoices)
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
            selected = dbStore.database?.resolveOne(bucket.parent)
        }
        
        if bucket.budgetID == nil {
            hasBudget = false
        } else {
            selectedSchedule = dbStore.database?.resolveOne(bucket.budget)
        }
    }
    
    func storeState() -> Bool {
        bucket.parentID = selected?.id
        if let ancestor = selected?.ancestorID {
            bucket.ancestorID = ancestor
        } else {
            bucket.ancestorID = bucket.parentID
        }
        
        if hasBudget {
            bucket.budgetID = nil
        } else {
            bucket.budgetID = selectedSchedule?.id
        }
        return true
    }
}
