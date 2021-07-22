//
//  MacTransactionView.swift
//  macOS
//
//  Created by Eric Nims on 6/18/21.
//

import SwiftUI
import GRDB

struct MacTransactionView: View {
    @EnvironmentObject var appState: GlobalState
    
    
    @EnvironmentObject var store: DatabaseStore
    @StateObject var selected: ObservableStructWrapper<TransactionData> = ObservableStructWrapper<TransactionData>()
    @State var activeSheet : ActiveSheet? = nil
    @State var activeAlert : ActiveAlert? = nil
    let selectedBucket: Bucket
    @State var editTags = false
    @State var contextSelection: TransactionData?
    
    var body: some View {
        VStack {
            HStack {
                TableToolbar(onClick: { action in
                    switch action {
                    case .new:
                        activeSheet = .new
                    case .edit:
                        if selected.wrappedStruct != nil {
                            activeSheet = .edit
                        } else {
                            activeAlert = .selectSomething
                        }
                    case .delete:
                        if selected.wrappedStruct != nil {
                            activeAlert = .confirmDelete
                        } else {
                            activeAlert = .selectSomething
                        }
                    }
                })
                
                Spacer()
                Toggle(isOn: $appState.includeTree, label: { Text("Show All Transactions") })
                Spacer()
                EnumPicker(label: "Sort By", selection: $appState.sorting, enumCases: TransactionModelRequest.Ordering.allCases)
                EnumPicker(label: "", selection: $appState.sortDirection, enumCases: TransactionModelRequest.OrderDirection.allCases).pickerStyle(SegmentedPickerStyle())
//                Button(action: {
//                    let yearsToAdd = 1
//                    let currentDate = Date()
//
//                    var dateComponent = DateComponents()
//                    dateComponent.year = yearsToAdd
//
//                    let futureDate = Calendar.current.date(byAdding: dateComponent, to: currentDate)
//                    let result = ScheduleRenderer.render(appDB: store.database!, schedule: store.schedules.first!, from: currentDate, to: futureDate!)
//                    print(result)
//                }){
//                    Text("Ref Recurring")
//                }
                Spacer(minLength: 15)
            }
            
            QueryWrapperView(source: TransactionModelRequest(
                                TransactionFilter(includeTree: appState.includeTree,
                                                  bucket: selectedBucket),
                                                  order: appState.sorting,
                                                  direction: appState.sortDirection)){ model in
                
                if appState.selectedView == .List {
                    ListTransactionsView(transactions: model,
                                         bucketName: selectedBucket.name,
                                         bucketID: selectedBucket.id!,
                                         selection: $selected.wrappedStruct)
                }
                
                if appState.selectedView == .Table {
                    TableTransactionsView(transactions: model,
                                          bucketName: selectedBucket.name,
                                          bucketID: selectedBucket.id!,
                                          selection: $selected.wrappedStruct)
                }
                
                HStack(alignment: .firstTextBaseline) {
                    Spacer()
                    Text("\(model.count) transactions")
                    Spacer()
                    Picker(selection: $appState.selectedView, label: Text("")) {
                        ForEach(TransactionViewType.allCases) { tStatus in
                            Image(systemName: tStatus.getIconName()).tag(tStatus)
                        }
                    }.pickerStyle(SegmentedPickerStyle()).frame(width: 160)
                }.frame(height: 30)
            }
        }.navigationTitle(selectedBucket.name)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .new:
                TransactionForm(onSubmit: {data in
                    store.updateTransaction(&data, onComplete: dismissModal)
                }, onCancel: dismissModal).padding()
            case .edit:
                TransactionForm(transaction: selected.wrappedStruct!.transaction, onSubmit: {data in
                    store.updateTransaction(&data, onComplete: dismissModal)
                }, onCancel: dismissModal).padding()
            }
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .deleteFail:
                return Alert(
                    title: Text("Database Error"),
                    message: Text("Failed to delete transaction"),
                    dismissButton: .default(Text("OK"))
                )
            case .selectSomething:
                return Alert(
                    title: Text("Alert"),
                    message: Text("Select a transaction first"),
                    dismissButton: .default(Text("OK"))
                )
            case .confirmDelete:
                return Alert(
                    title: Text("Confirm Delete"),
                    message: Text("Are you sure you want to delete this?"),
                    primaryButton: .cancel(),
                    secondaryButton: .destructive(Text("Confirm"), action: {
                        if let sel = selected.wrappedStruct {
                            store.deleteTransaction(sel.transaction.id!)
                            selected.wrappedStruct = nil
                        }
                    })
                )
            }
        }
    }
    
    func dismissModal(){
        activeSheet = nil
    }
}

enum ActiveSheet: String, Identifiable {
    case new, edit
    
    var id: String { return self.rawValue }
}

enum ActiveAlert : String, Identifiable { // <--- note that it's now Identifiable
    case deleteFail, selectSomething, confirmDelete
    
    var id: String { return self.rawValue }
}

enum TransactionViewType: String, CaseIterable, Identifiable, Stringable {
    case List
    case Table
    case Calendar
        
    var id: String { self.rawValue }
    
    func getStringName() -> String {
        return self.id
    }
    
    func getIconName() -> String {
        switch self {
        case .List:
            return "list.bullet"
        case .Table:
            return "tablecells"
        case .Calendar:
            return "calendar"
        }
    }
}

//struct MacTransactionView_Previews: PreviewProvider {
//    static var previews: some View {
//        MacTransactionView()
//    }
//}
