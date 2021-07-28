//
//  ScheduleTable.swift
//  SPENT
//
//  Created by Eric Nims on 6/19/21.
//

import SwiftUI
import SwiftUIKit

struct ScheduleTable: View {

    @EnvironmentObject var store: DatabaseStore
    @StateObject private var context = SheetContext()
    @StateObject private var aContext = AlertContext()
    
    var schedules: [Schedule]
    @State var selected: Schedule?
    
    var body: some View {
        VStack{
            Section(header:
                VStack {
                    HStack {
                        TableToolbar(onClick: { action in
                            switch action {
                            case .new:
                                context.present(UIForms.schedule(context: context, schedule: nil, onSubmit: {data in
                                    store.updateSchedule(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
                                }))
                            case .edit:
                                if selected != nil {
                                    context.present(UIForms.schedule(context: context, schedule: selected!, onSubmit: {data in
                                        store.updateSchedule(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
                                    }))
                                } else {
                                    aContext.present(UIAlerts.message(message: "Select a tag first"))
                                }
                            case .delete:
                                if selected != nil {
                                    context.present(UIForms.confirmDelete(context: context, message: "", onConfirm: {
                                        store.deleteSchedule(selected!.id!, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
                                    }))
                                } else {
                                    aContext.present(UIAlerts.message(message: "Select a tag first"))
                                }
                            }
                        })
                        Spacer()
                    }
                    Header()
                }){}
            List(schedules, id: \.self, selection: $selected){ schedule in
                Row(schedule: schedule).tag(schedule)
            }
        }.sheet(context: context).alert(context: aContext)
    }
    
    struct Header: View {
        var body: some View {
            TableRow(content: [
                AnyView(TableCell {
                    Text("Name")
                }),
                AnyView(TableCell {
                    Text("Type")
                }),
                AnyView(TableCell {
                    Text("Rule")
                }),
                AnyView(TableCell {
                    Text("Marker ID")
                }),
                AnyView(TableCell {
                    Text("Memo")
                })
            ], showDivider: false)
        }
    }
    
    struct Row: View {
        
        //TODO: This should really be a binding
        @State var schedule: Schedule
        
        var body: some View {
            TableRow(content: [
                AnyView(TableCell {
                    Text(schedule.name)
                }),
                AnyView(TableCell {
                    Text(schedule.scheduleType.getStringName())
                }),
                AnyView(TableCell {
                    Text(schedule.rule.getStringName())
                }),
                AnyView(TableCell {
                    Text("\(schedule.markerID)")
                }),
                AnyView(TableCell {
                    Text(schedule.memo.trunc(length: 10))
                })
            ], showDivider: false)
        }
    }
}


//struct ScheduleTable_Previews: PreviewProvider {
//    static var previews: some View {
//        ScheduleTable()
//    }
//}
