//
//  ScheduleForm.swift
//  SPENT
//
//  Created by Eric Nims on 6/19/21.
//

import SwiftUI

struct ScheduleForm: View {
    @EnvironmentObject var dbStore: DatabaseStore
    @State var schedule: Schedule = Schedule(id: nil, name: "", scheduleType: .OneTime, rule: .Never, markerID: -1, memo: "")
    @State fileprivate var marker: Tag?
    
    let markerChoices: [Tag]

    /*
     var name: String
     var scheduleType: ScheduleType
     var rule: ScheduleRule
     var customRule: String? // TODO: Change this to the correct type
     var markerID: Int64
     var memo: String?
     */
    
    let onSubmit: (_ data: inout Schedule) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack{
            Form {
                TextField("Name", text: $schedule.name)
                EnumPicker(label: "Type", selection: $schedule.scheduleType, enumCases: Schedule.ScheduleType.allCases)
                EnumPicker(label: "Rule", selection: $schedule.rule, enumCases: Schedule.ScheduleRule.allCases)
                // TODO: Add support for custom rules
                
                Text(marker?.name ?? "N/A")
                TagPicker(label: "Marker", selection: $marker, choices: markerChoices)
                
                TextEditor(text: $schedule.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            }//.navigationTitle(Text(title))
            .toolbar(content: {
                ToolbarItem(placement: .confirmationAction){
                    Button("Done", action: {
                        if storeState() {
                            onSubmit(&schedule)
                        } else {
                            //TODO: Show an alert or some "Invalid Data" indicator
                            print("Schedule storeState failed!")
                        }
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
    
    func loadState(){
        if schedule.markerID == -1 {
            // TODO: This will crash if there are no tags defined
            self.marker = markerChoices.first!
        } else {
            self.marker = dbStore.database?.resolveOne(schedule.marker)
        }
    }
    
    func storeState() -> Bool {
        schedule.markerID = self.marker!.id!
        
        return true
    }
}


//struct ScheduleForm_Previews: PreviewProvider {
//    static var previews: some View {
//        ScheduleForm()
//    }
//}
