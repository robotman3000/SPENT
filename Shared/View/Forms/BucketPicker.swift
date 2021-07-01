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
    @Query(BucketRequest()) var bucketChoices: [Bucket]
    
    var body: some View {
        Picker(selection: $selection, label: Text(label)) {
            ForEach(bucketChoices, id: \.id) { bucket in
                Text(bucket.name).tag(bucket as Bucket?)
            }
        }
    }
}

//struct BucketPicker_Previews: PreviewProvider {
//    static var previews: some View {
//        BucketPicker()
//    }
//}
