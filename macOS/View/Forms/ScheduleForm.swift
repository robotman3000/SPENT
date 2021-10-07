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
    @State var selected: DBTransactionTemplate?
    
    @Query(TemplateRequest()) var templates: [DBTransactionTemplate]
    
    let onSubmit: (_ data: inout Schedule) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack{
            Form {
                TextField("Name", text: $schedule.name)
                Toggle("Favorite", isOn: $schedule.isFavorite)
                
                QueryWrapperView(source: TemplateRequest()){ templateList in
                    Picker(selection: $selected, label: Text("Template: ")) {
                        ForEach(templateList, id: \.id) { template in
                            let templateData = try! template.decodeTemplate()
                            if let templData = templateData {
                                Text(templData.name).tag(template as DBTransactionTemplate?)
                            }
                        }
                    }
                }
                
                TextEditor(text: $schedule.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            }.frame(minWidth: 250, minHeight: 200)
            .onAppear { loadState() }
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
        for template in templates {
            if template.id == schedule.templateID {
                selected = template
            }
        }
    }
    
    func storeState() -> Bool {
        if selected == nil || schedule.name.isEmpty {
            return false
        }
        
        schedule.templateID = selected!.id!
        return true
    }
}


//struct ScheduleForm_Previews: PreviewProvider {
//    static var previews: some View {
//        ScheduleForm()
//    }
//}
