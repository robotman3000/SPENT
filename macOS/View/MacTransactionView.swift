//
//  MacTransactionView.swift
//  macOS
//
//  Created by Eric Nims on 6/18/21.
//

import SwiftUI
import GRDB

struct MacTransactionView: View {
    
    @Environment(\.appDatabase) private var database: AppDatabase?
    @EnvironmentObject var store: DatabaseStore
    @ObservedObject var model: TransactionViewModel
    @EnvironmentObject var appState: GlobalState
    @StateObject var selected: ObservableStructWrapper<Transaction> = ObservableStructWrapper<Transaction>()
    @State var activeSheet : ActiveSheet? = nil
    @State var activeAlert : ActiveAlert? = nil
    
    init(contextBucket: Bucket) {
        model = TransactionViewModel(query: Transaction.all(), bucket: contextBucket)
    }
    
    var body: some View {
        VStack {
            HStack {
                TableToolbar(selected: $selected.wrappedStruct, activeSheet: $activeSheet, activeAlert: $activeAlert)
                //FilterBar(query: $model.query)
                Spacer()
                Picker("View As", selection: $appState.selectedView) {
                    ForEach(TransactionViewType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
            }
            Spacer()
            switch appState.selectedView {
            case .List: ListTransactionsView(transactions: model.transactions,
                                             transactionTags: model.tags,
                                             selection: $selected.wrappedStruct,
                                             bucket: model.contextBucket).onAppear(perform: {print("list appear")})
            case .Table: TableTransactionsView(transactions: model.transactions,
                                               selection: $selected.wrappedStruct,
                                               bucket: model.contextBucket).onAppear(perform: {print("table appear")})
            case .Calendar: Text("Calendar View")
            }
        }.sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .new:
                TransactionForm(title: "Create Transaction", onSubmit: {data in
                    store.updateTransaction(&data, onComplete: dismissModal)
                }, onCancel: dismissModal).padding()
            case .edit:
                TransactionForm(title: "Create Transaction", transaction: selected.wrappedStruct!, onSubmit: {data in
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
                        store.deleteTransaction(selected.wrappedStruct!.id!)
                    })
                )
            }
        }
        .onAppear(perform: {
            print("mav view render")
            model.load(database!)
        })
    }
    
    func dismissModal(){
        activeSheet = nil
    }
}

enum TransactionViewType: String, CaseIterable, Identifiable {
    case List
    case Table
    case Calendar
        
    var id: String { self.rawValue }
}

//struct MacTransactionView_Previews: PreviewProvider {
//    static var previews: some View {
//        MacTransactionView()
//    }
//}
