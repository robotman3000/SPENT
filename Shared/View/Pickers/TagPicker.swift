//
//  TagPicker.swift
//  SPENT
//
//  Created by Eric Nims on 7/21/21.
//

import SwiftUI

struct TagPicker: View {

    var label: String = ""
    @Binding var selection: Tag?
    var choices: [Tag]
    
    var body: some View {
        if !choices.isEmpty {
            Picker(selection: $selection, label: Text(label)) {
                ForEach(choices, id: \.id) { tag in
                    Text(tag.name).tag(tag as Tag?)
                }
            }
        } else {
            Text("No Options")
        }
    }
}

//struct BucketPicker_Previews: PreviewProvider {
//    static var previews: some View {
//        BucketPicker()
//    }
//}
