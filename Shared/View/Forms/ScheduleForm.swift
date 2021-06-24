//
//  ScheduleForm.swift
//  SPENT
//
//  Created by Eric Nims on 6/19/21.
//

import SwiftUI

struct ScheduleForm: View {
    let title: String
    @State var schedule: Schedule = Schedule(id: nil, name: "", scheduleType: .OneTime, rule: .Never, markerID: -1)
    
    let onSubmit: (_ data: inout Schedule) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack{
            Form {
                TextField("Name", text: $schedule.name)
                // TODO: Finish this
            }//.navigationTitle(Text(title))
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction){
                    Button("Done", action: {
                        onSubmit(&schedule)
                    })
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: {
                        onCancel()
                    })
                }
            })
        }
    }
}


//struct ScheduleForm_Previews: PreviewProvider {
//    static var previews: some View {
//        ScheduleForm()
//    }
//}
