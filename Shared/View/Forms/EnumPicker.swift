//
//  EnumPicker.swift
//  SPENT
//
//  Created by Eric Nims on 7/1/21.
//

import SwiftUI

struct EnumPicker<Type: Identifiable & Hashable & Stringable>: View {
    
    let label: String
    @Binding var selection: Type
    let enumCases: [Type]
    
    var body: some View {
        Picker(selection: $selection, label: Text(label)) {
            ForEach(enumCases) { tStatus in
                Text(tStatus.getStringName()).tag(tStatus)
            }
        }
    }
}

//struct EnumPicker_Previews: PreviewProvider {
//    static var previews: some View {
//        EnumPicker()
//    }
//}
