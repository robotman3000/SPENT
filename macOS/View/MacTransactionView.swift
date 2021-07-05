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
    @StateObject var selected: ObservableStructWrapper<TransactionData> = ObservableStructWrapper<TransactionData>()
    @State var activeSheet : ActiveSheet? = nil
    @State var activeAlert : ActiveAlert? = nil
    let selectedBucket: Bucket
    
    var body: some View {
        VStack {
            HStack {
                TableToolbar(selected: $selected.wrappedStruct, activeSheet: $activeSheet, activeAlert: $activeAlert)
                EnumPicker(label: "View As", selection: $appState.selectedView, enumCases: TransactionViewType.allCases)
                Spacer(minLength: 10)
            }
            
            QueryWrapperView(source: TransactionModelRequest(TransactionFilter(includeTree: (selectedBucket.ancestorID == nil), bucket: selectedBucket))){ model in
                switch appState.selectedView {
                case .List: ListTransactionsView(transactions: model,
                                                 bucketName: selectedBucket.name,
                                                 bucketID: selectedBucket.id!,
                                                 selection: $selected.wrappedStruct)
                case .Table: TableTransactionsView(transactions: model,
                                                   bucketName: selectedBucket.name,
                                                   bucketID: selectedBucket.id!,
                                                   selection: $selected.wrappedStruct)
                case .Calendar: Text("Calendar View")
                }
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
                        store.deleteTransaction(selected.wrappedStruct!.transaction.id!)
                        selected.wrappedStruct = nil
                    })
                )
            }
        }
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
