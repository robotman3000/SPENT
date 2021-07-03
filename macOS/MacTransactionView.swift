//
//  MacTransactionView.swift
//  macOS
//
//  Created by Eric Nims on 6/18/21.
//

import SwiftUI
import GRDB

struct MacTransactionView: View {
    @EnvironmentObject var store: DatabaseStore
    @EnvironmentObject var appState: GlobalState
    @ObservedObject var model: TransactionViewModel
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
                EnumPicker(label: "View As", selection: $appState.selectedView, enumCases: TransactionViewType.allCases)
                Spacer(minLength: 10)
            }
            switch appState.selectedView {
            case .List: ListTransactionsView(transactions: model.transactions,
                                             bucketName: model.contextBucket.name, selection: $selected.wrappedStruct)
            case .Table: TableTransactionsView(transactions: model.transactions,
                                               bucket: model.contextBucket, selection: $selected.wrappedStruct)
            case .Calendar: Text("Calendar View")
            }
        }.navigationTitle(model.contextBucket.name)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .new:
                TransactionForm(onSubmit: {data in
                    store.updateTransaction(&data, onComplete: dismissModal)
                }, onCancel: dismissModal).padding()
            case .edit:
                TransactionForm(transaction: selected.wrappedStruct!, onSubmit: {data in
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
            model.load(store.database!)
        })
    }
    
    func dismissModal(){
        activeSheet = nil
    }
}

enum TransactionViewType: String, CaseIterable, Identifiable, Stringable {
    case List
    case Table
    case Calendar
        
    var id: String { self.rawValue }
    
    func getStringName() -> String {
        return self.id
    }
}

//struct MacTransactionView_Previews: PreviewProvider {
//    static var previews: some View {
//        MacTransactionView()
//    }
//}
