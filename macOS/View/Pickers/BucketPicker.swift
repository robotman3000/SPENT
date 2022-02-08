//
//  BucketPicker.swift
//  SPENT
//
//  Created by Eric Nims on 7/1/21.
//

import SwiftUI

struct BucketPicker: View {

    var label: String = ""
    @Binding var selection: Bucket?
    let choices: [Bucket]
    
    var body: some View {
        if !choices.isEmpty {
            Picker(selection: $selection, label: Text(label)) {
                ForEach(choices, id: \.id) { bucket in
                    Text(bucket.name).tag(bucket as Bucket?)
                }
            }
        } else {
            Text("No Buckets")
        }
    }
}

//struct BucketPicker_Previews: PreviewProvider {
//    static var previews: some View {
//        BucketPicker()
//    }
//}
