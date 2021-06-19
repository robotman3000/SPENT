//
//  ScheduleTable.swift
//  SPENT
//
//  Created by Eric Nims on 6/19/21.
//

import SwiftUI

struct ScheduleTable: View {

    @Query(ScheduleRequest(order: .none)) var schedules: [Schedule]
    @State var selectedS: Schedule?
    @Binding var activeSheet : ActiveSheet?
    @Binding var activeAlert : ActiveAlert?
    
    var body: some View {
        VStack{
            Section(header:
                VStack {
                    HStack {
                        TableToolbar(selected: $selectedS, activeSheet: $activeSheet, activeAlert: $activeAlert)
                        Spacer()
                    }
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
                }){}
            List(schedules, id: \.self, selection: $selectedS){ schedule in
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
}


//struct ScheduleTable_Previews: PreviewProvider {
//    static var previews: some View {
//        ScheduleTable()
//    }
//}
