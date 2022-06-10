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
    var allowEmpty: Bool = false
    
    var body: some View {
        if !(!allowEmpty && choices.isEmpty) {
            Picker(selection: $selection, label: Text(label)) {
                if allowEmpty {
                    Text("").tag(nil as Bucket?)
                }
                ForEach(choices, id: \.id) { bucket in
                    Text(bucket.displayName).tag(bucket as Bucket?)
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
