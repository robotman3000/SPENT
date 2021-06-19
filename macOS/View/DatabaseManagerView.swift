//
//  DatabaseManagerView.swift
//  SPENT
//
//  Created by Eric Nims on 6/18/21.
//

import SwiftUI

struct DatabaseManagerView: View {
    
    let onCancel: () -> Void
    
    @State var activeSheet : ActiveSheet? = nil
    @State var activeAlert : ActiveAlert? = nil
    @State fileprivate var editType: DatabaseEditorTab = .account
    
    var body: some View {
        VStack{
            TabView {
                BucketTable(activeSheet: $activeSheet, activeAlert: $activeAlert).tabItem {
                    Label("Accounts", systemImage: "folder")
                }.onAppear(perform: {editType = .account})
             
                ScheduleTable(activeSheet: $activeSheet, activeAlert: $activeAlert).tabItem {
                    Label("Schedules", systemImage: "calendar.badge.clock")
                }.onAppear(perform: {editType = .schedule})
         
                TagTable(activeSheet: $activeSheet, activeAlert: $activeAlert).tabItem {
                    Label("Tags", systemImage: "tag")
                }.onAppear(perform: {editType = .tag})
            }.sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .new:
                    switch editType {
                    case .account: BucketForm(title: "New Bucket", onSubmit: <#T##(inout Bucket) -> Void#>, onCancel: <#T##() -> Void#>)
                    case .schedule: Text("4543")
                    case .tag: Text("4543")
                    }
                case .edit:
                    switch editType {
                    case .account: Text("4543")
                    case .schedule: Text("4543")
                    case .tag: Text("4543")
                    }
                }
            }.alert(item: $activeAlert) { alert in
                switch alert {
                case .deleteFail:
                    return Alert(
                        title: Text("Database Error"),
                        message: Text("Failed to delete record"),
                        dismissButton: .default(Text("OK"))
                    )
                case .selectSomething:
                    return Alert(
                        title: Text("Alert"),
                        message: Text("Select a row first"),
                        dismissButton: .default(Text("OK"))
                    )
                case .confirmDelete:
                    return Alert(
                        title: Text("Confirm Delete"),
                        message: Text("Are you sure you want to delete this?"),
                        primaryButton: .cancel(),
                        secondaryButton: .destructive(Text("Confirm"), action: {
                            //deleteTransaction(selected!.id!)
                        })
                    )
                }
            }
            HStack {
                Spacer()
                Button("Done", action: {
                    onCancel()
                })
            }
        }.padding().frame(minWidth: 600, minHeight: 400)
    }
}

private enum DatabaseEditorTab: String, CaseIterable, Identifiable {
    case account, schedule, tag
    
    var id: String { self.rawValue }
}

//struct DatabaseManagerView_Previews: PreviewProvider {
//    static var previews: some View {
//        DatabaseManagerView()
//    }
//}
