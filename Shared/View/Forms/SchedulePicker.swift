//
//  SchedulePicker.swift
//  SPENT
//
//  Created by Eric Nims on 7/1/21.
//

import SwiftUI

struct SchedulePicker: View {
    var label: String = ""
    @Binding var selection: Schedule?
    var choices: [Schedule]
    
    var body: some View {
        Picker(selection: $selection, label: Text(label)) {
            ForEach(choices, id: \.id) { schedule in
                Text(schedule.name).tag(schedule as Schedule?)
            }
        }
    }
}

//struct SchedulePicker_Previews: PreviewProvider {
//    static var previews: some View {
//        SchedulePicker()
//    }
//}
