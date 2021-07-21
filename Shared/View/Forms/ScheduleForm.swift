//
//  ScheduleForm.swift
//  SPENT
//
//  Created by Eric Nims on 6/19/21.
//

import SwiftUI

struct ScheduleForm: View {
    @EnvironmentObject var dbStore: DatabaseStore
    let title: String
    @State var schedule: Schedule = Schedule(id: nil, name: "", scheduleType: .OneTime, rule: .Never, markerID: -1, memo: "")
    @StateObject var marker: ObservableStructWrapper<Tag> = ObservableStructWrapper<Tag>()
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
                
                Text(marker.wrappedStruct?.name ?? "N/A")
                TagPicker(label: "Marker", selection: $marker.wrappedStruct, choices: markerChoices)
                
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
            self.marker.wrappedStruct = self.markerChoices.first!
        } else {
            self.marker.wrappedStruct = dbStore.database?.resolveOne(schedule.marker)
        }
    }
    
    func storeState() -> Bool {
        schedule.markerID = self.marker.wrappedStruct!.id!
        
        return true
    }
}


//struct ScheduleForm_Previews: PreviewProvider {
//    static var previews: some View {
//        ScheduleForm()
//    }
//}
