//
//  BucketEditForm.swift
//  iOS
//
//  Created by Eric Nims on 4/21/21.
//

import SwiftUI

struct BucketForm: View {
    let title: String
    
    @State var bucket: Bucket = Bucket(id: nil, name: "")
    @State var selectedParentIndex = 0
    @State var isAccount = false
    @Query(BucketRequest()) var parentChoices: [Bucket]
    
    let onSubmit: (_ data: inout Bucket) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack{
            Form {
                TextField("Name", text: $bucket.name)
                
                Toggle("Is Account", isOn: $isAccount)
                Picker(selection: $selectedParentIndex, label: Text("Parent")) {
                    ForEach(0 ..< parentChoices.count) {
                        Text(self.parentChoices[$0].name)
                    }
                }.disabled(isAccount)
                
                TextField("Memo", text: $bucket.memo)
            }//.navigationTitle(Text(title))
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: {
                        onCancel()
                    })
                }
                ToolbarItem(placement: .confirmationAction){
                    Button("Done", action: {
                        if isAccount {
                            bucket.parentID = nil
                            bucket.ancestorID = nil
                        } else {
                            bucket.parentID = parentChoices[selectedParentIndex].id
                            //TODO: Ensure the ancestor is correct
                        }
                        onSubmit(&bucket)
                    })
                }
            })
        }.onAppear {
            if bucket.parentID == nil {
                isAccount = true
            }
            
            var result = false
            for (index, bucketChoice) in parentChoices.enumerated() {
                if bucketChoice.id == bucket.parentID {
                    selectedParentIndex = index
                    result = true
                    break
                }
            }
            
            if !result && !isAccount {
                print("Warning: No match was found for the bucket parent in the provided choices")
            }
        }
    }
}
