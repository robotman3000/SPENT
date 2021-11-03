//
//  ScheduleManagerView.swift
//  macOS
//
//  Created by Eric Nims on 8/26/21.
//

import SwiftUI
import SwiftUIKit

struct ScheduleManagerView: View {
    @EnvironmentObject fileprivate var store: DatabaseStore
    @State var selected: Schedule?
    @StateObject private var context = SheetContext()
    @StateObject private var aContext = AlertContext()
    
    var body: some View {
        if store.database != nil {
            VStack{
                HStack {
                    TableToolbar(onClick: { action in
                        switch action {
                        case .new:
                            context.present(FormKeys.schedule(context: context, schedule: nil, onSubmit: {data in
                                store.updateSchedule(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                            }))
                        case .edit:
                            if selected != nil {
                                context.present(FormKeys.schedule(context: context, schedule: selected!, onSubmit: {data in
                                    store.updateSchedule(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                                }))
                            } else {
                                aContext.present(AlertKeys.message(message: "Select a schedule first"))
                            }
                        case .delete:
                            if selected != nil {
                                context.present(FormKeys.confirmDelete(context: context, message: "", onConfirm: {
                                    store.deleteSchedule(selected!.id!, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                                }))
                            } else {
                                aContext.present(AlertKeys.message(message: "Select a schedule first"))
                            }
                        }
                    })
                    Button("Render"){
                        if selected != nil {
                            
                        } else {
                            aContext.present(AlertKeys.message(message: "Select a schedule first"))
                        }
                    }
                    Spacer()
                }
                QueryWrapperView(source: ScheduleFilter()){ scheduleIDs in
                    List(scheduleIDs, id: \.self, selection: $selected) { scheduleID in
                        AsyncContentView(source: ScheduleFilter.publisher(store.getReader(), forID: scheduleID)){ schedule in
                            Text(schedule.name)
                            //Row(tag: tag).tag(tag)
                        }
                    }
                }
            }.sheet(context: context).alert(context: aContext)
        } else {
            Text("No database is loaded").frame(width: 100, height: 100)
        }
    }
}

struct ScheduleManagerView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleManagerView()
    }
}
