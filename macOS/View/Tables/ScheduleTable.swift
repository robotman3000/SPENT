//
//  ScheduleTable.swift
//  SPENT
//
//  Created by Eric Nims on 6/19/21.
//

import SwiftUI

struct ScheduleTable: View {

    @Environment(\.appDatabase) private var database: AppDatabase?
    @Query(ScheduleRequest(order: .none)) var schedules: [Schedule]
    @State var selected: Schedule?
    @State var activeSheet : ActiveSheet? = nil
    @State var activeAlert : ActiveAlert? = nil
    
    var body: some View {
        VStack{
            Section(header:
                VStack {
                    HStack {
                        TableToolbar(selected: $selected, activeSheet: $activeSheet, activeAlert: $activeAlert)
                        Spacer()
                    }
                    Header()
                }){}
            List(schedules, id: \.self, selection: $selected){ schedule in
                Row(schedule: schedule).tag(schedule)
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .new:
                ScheduleForm(title: "Create Schedule", onSubmit: {data in
                    updateSchedule(&data, database: database!, onComplete: dismissModal)
                }, onCancel: dismissModal).padding()
            case .edit:
                ScheduleForm(title: "Edit Schedule", schedule: selected!, onSubmit: {data in
                    updateSchedule(&data, database: database!, onComplete: dismissModal)
                }, onCancel: dismissModal).padding()
            }
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .deleteFail:
                return Alert(
                    title: Text("Database Error"),
                    message: Text("Failed to delete schedule"),
                    dismissButton: .default(Text("OK"))
                )
            case .selectSomething:
                return Alert(
                    title: Text("Alert"),
                    message: Text("Select a schedule first"),
                    dismissButton: .default(Text("OK"))
                )
            case .confirmDelete:
                return Alert(
                    title: Text("Confirm Delete"),
                    message: Text("Are you sure you want to delete this?"),
                    primaryButton: .cancel(),
                    secondaryButton: .destructive(Text("Confirm"), action: {
                        deleteSchedule(selected!.id!, database: database!)
                    })
                )
            }
        }
    }
    
    func dismissModal(){
        activeSheet = nil
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
            ])
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
                    Text(schedule.memo ?? "N/A")
                })
            ])
        }
    }
}


//struct ScheduleTable_Previews: PreviewProvider {
//    static var previews: some View {
//        ScheduleTable()
//    }
//}