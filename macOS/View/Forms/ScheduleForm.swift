//
//  ScheduleForm.swift
//  SPENT
//
//  Created by Eric Nims on 6/19/21.
//

import SwiftUI

struct ScheduleForm: View {
    @EnvironmentObject var dbStore: DatabaseStore
    @State var schedule: Schedule = Schedule(id: nil, name: "", templateID: -1)
    @State fileprivate var marker: Tag?
    
    @Query(TagRequest()) var markerChoices: [Tag]
    
    let onSubmit: (_ data: inout Schedule) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack{
            Form {
                TextField("Name", text: $schedule.name)
                Toggle("Favorite", isOn: $schedule.isFavorite)
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

    }
    
    func storeState() -> Bool {
        
        return true
    }
}


//struct ScheduleForm_Previews: PreviewProvider {
//    static var previews: some View {
//        ScheduleForm()
//    }
//}
