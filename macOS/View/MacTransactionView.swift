//
//  MacTransactionView.swift
//  macOS
//
//  Created by Eric Nims on 6/18/21.
//

import SwiftUI
import SwiftUIKit
import GRDB

struct MacTransactionView: View {
    @EnvironmentObject var appState: GlobalState
    
    
    @EnvironmentObject var store: DatabaseStore
    @State var selected: Set<TransactionData> = Set<TransactionData>()
    let selectedBucket: Bucket
    @State var editTags = false
    @State var contextSelection: TransactionData?
    
    @StateObject private var context = SheetContext()
    @StateObject private var aContext = AlertContext()
    
    var body: some View {
        VStack {
            HStack {
                Toggle(isOn: $appState.includeTree, label: { Text("Show All Transactions") })
                Toggle(isOn: $appState.showTags, label: { Text("Show Tags") })
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
            }.padding()
            
            QueryWrapperView(source: TransactionModelRequest(
                                TransactionFilter(includeTree: appState.includeTree,
                                                  bucket: selectedBucket),
                                                  order: appState.sorting,
                                                  direction: appState.sortDirection)){ model in
                
                VStack{
//                    if appState.selectedView == .List {
//                        ListTransactionsView(transactions: model,
//                                             bucket: selectedBucket,
//                                             selection: $selected,
//                                             context: context,
//                                             aContext: aContext)
//                    }
                    
                    if appState.selectedView == .Table {
                        TableTransactionsView(transactions: model,
                                              bucket: selectedBucket,
                                              selection: $selected,
                                              context: context,
                                              aContext: aContext)
                    }
                }.contextMenu {
                    Button("Add Transaction") {
                        context.present(UIForms.transaction(context: context, transaction: nil, contextBucket: selectedBucket, onSubmit: {data in
                            store.updateTransaction(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
                        }))
                    }
                    
                    Button("Add Transfer"){
                        context.present(UIForms.transfer(context: context, transaction: nil, contextBucket: selectedBucket, sourceChoices: store.buckets, destChoices: store.buckets, onSubmit: {data in
                            store.updateTransaction(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
                        }))
                    }
                }
//                if appState.selectedView == .Calendar {
//
//                }
                
                HStack(alignment: .firstTextBaseline) {
                    Button(action: {
                        context.present(UIForms.transaction(context: context, transaction: nil, contextBucket: selectedBucket, onSubmit: {data in
                            store.updateTransaction(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
                        }))
                    }) {
                        Image(systemName: "plus")
                    }
                    Spacer()
                    Text("\(model.count) transactions")
                    Spacer()
//                    Picker(selection: $appState.selectedView, label: Text("")) {
//                        ForEach(TransactionViewType.allCases) { tStatus in
//                            Image(systemName: tStatus.getIconName()).tag(tStatus)
//                        }
//                    }.pickerStyle(SegmentedPickerStyle()).frame(width: 160)
                }.padding().frame(height: 30)
            }
        }.navigationTitle(selectedBucket.name).sheet(context: context).alert(context: aContext)
    }
}

struct TransactionContextMenu: View {
    @ObservedObject var context: SheetContext
    @ObservedObject var aContext: AlertContext
    @EnvironmentObject var store: DatabaseStore
    
    let contextBucket: Bucket
    let transactions: Set<TransactionData>
    
    var body: some View {
        Section{
            Button("Add Transaction") {
                context.present(UIForms.transaction(context: context, transaction: nil, contextBucket: contextBucket, onSubmit: {data in
                    store.updateTransaction(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
                }))
            }
            
            Button("Add Transfer"){
                context.present(UIForms.transfer(context: context, transaction: nil, contextBucket: contextBucket, sourceChoices: store.buckets, destChoices: store.buckets, onSubmit: {data in
                    store.updateTransaction(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
                }))
            }
        }
        Section {
            if let t = transactions.first { // No support for batch editing... yet
                if transactions.count == 1 {
                    if t.transaction.type == .Transfer {
                        Button("Edit Transfer") {
                            context.present(UIForms.transfer(context: context, transaction: t.transaction, contextBucket: contextBucket, sourceChoices: store.buckets, destChoices: store.buckets, onSubmit: {data in
                                store.updateTransaction(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
                            }))
                        }
                    } else {
                        Button("Edit Transaction") {
                            context.present(UIForms.transaction(context: context, transaction: t.transaction, contextBucket: contextBucket, onSubmit: {data in
                                store.updateTransaction(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
                            }))
                        }
                    }
                    
                    Button("Add Document") {
                        aContext.present(UIAlerts.notImplemented)
                    }
                }
            }
        
            Button("Set Tags") {
                context.present(
                    UIForms.transactionTags(
                        context: context,
                        transaction: transactions.first!.transaction,
                        currentTags: transactions.count == 1 ? Set(transactions.first!.tags) : Set(),
                        tagChoices: store.tags,
                        onSubmit: {tags, transaction in
                            print(tags)
                            store.setTransactionsTags(transactions: transactions.map({ t in t.transaction }), tags: tags, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
                        }
                    )
                )
            }
        }
        
        Section{
            Button("Mark As Reconciled"){
                aContext.present(UIAlerts.notImplemented)
            }
            Menu("Mark As"){
                Text("Not Implemented")
            }
        }
        
        Button("Delete Selected") {
            context.present(UIForms.confirmDelete(context: context, message: "", onConfirm: {
                store.deleteTransactions(transactions.map({t in t.transaction.id!}), onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
            }))
        }
        
        Section{
            Button("Debug Info") {
                aContext.present(UIAlerts.message(message: transactions.debugDescription))
            }
        }
    }
}

enum TransactionViewType: String, CaseIterable, Identifiable, Stringable {
    case List
    case Table
    //case Calendar
        
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
        //case .Calendar:
        //    return "calendar"
        }
    }
}

//struct MacTransactionView_Previews: PreviewProvider {
//    static var previews: some View {
//        MacTransactionView()
//    }
//}
