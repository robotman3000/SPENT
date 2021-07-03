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
    @State var isAccount = false
    @State var hasBudget = false
    @StateObject var selected: ObservableStructWrapper<Bucket> = ObservableStructWrapper<Bucket>()
    @StateObject var selectedSchedule: ObservableStructWrapper<Schedule> = ObservableStructWrapper<Schedule>()
    
    let onSubmit: (_ data: inout Bucket) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            TextField("Name", text: $bucket.name)
            
            Section(){
                Toggle("Is Account", isOn: $isAccount)
                BucketPicker(label: "Parent", selection: $selected.wrappedStruct)
                    .disabled(isAccount)
            }
            
            Section(){
                Toggle("Enable Budget", isOn: $hasBudget)
                SchedulePicker(label: "Budget", selection: $selectedSchedule.wrappedStruct)
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
        if bucket.parentID == nil {
            isAccount = true
        } else {
            selected.wrappedStruct = dbStore.database?.resolveOne(bucket.parent)
        }
        
        if bucket.budgetID == nil {
            hasBudget = false
        } else {
            selectedSchedule.wrappedStruct = dbStore.database?.resolveOne(bucket.budget)
        }
    }
    
    func storeState() -> Bool {
        if isAccount {
            bucket.parentID = nil
            bucket.ancestorID = nil
        } else {
            bucket.parentID = selected.wrappedStruct?.id
            //TODO: Ensure the ancestor is correct
        }
        
        if hasBudget {
            bucket.budgetID = nil
        } else {
            bucket.budgetID = selectedSchedule.wrappedStruct?.id
        }
        return true
    }
}