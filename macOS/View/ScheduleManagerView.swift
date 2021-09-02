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
        VStack{
            HStack {
//                TableToolbar(onClick: { action in
//                    switch action {
//                    case .new:
//                        context.present(FormKeys.schedule(context: context, schedule: nil, markerChoices: store.tags, onSubmit: {data in
//                            store.updateSchedule(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
//                        }))
//                    case .edit:
//                        if selected != nil {
//                            context.present(FormKeys.schedule(context: context, schedule: selected!, markerChoices: store.tags, onSubmit: {data in
//                                store.updateSchedule(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
//                            }))
//                        } else {
//                            aContext.present(AlertKeys.message(message: "Select a tag first"))
//                        }
//                    case .delete:
//                        if selected != nil {
//                            context.present(FormKeys.confirmDelete(context: context, message: "", onConfirm: {
//                                store.deleteSchedule(selected!.id!, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
//                            }))
//                        } else {
//                            aContext.present(AlertKeys.message(message: "Select a tag first"))
//                        }
//                    }
//                })
                Spacer()
            }
            
            QueryWrapperView(source: ScheduleRequest()){ schedules in
                List(schedules, id: \.self, selection: $selected){ schedule in
                    Text(schedule.name)
                    //Row(tag: tag).tag(tag)
                }
            }
        }.sheet(context: context).alert(context: aContext)
    }
}

struct ScheduleManagerView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleManagerView()
    }
}
