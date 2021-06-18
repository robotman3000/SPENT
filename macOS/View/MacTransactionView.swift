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
    let title: String
    @State var query: TransactionRequest
    @State var selectedView = TransactionViewType.List
    @State var selected: Transaction?
    @State var activeSheet : ActiveSheet? = nil
    @State var activeAlert : ActiveAlert? = nil
    
    var body: some View {
        HStack {
            HStack {
                Button(action: { activeSheet = .new }) {
                    Image(systemName: "plus")
                }
                Button(action: {
                    if selected != nil {
                        activeSheet = .edit
                    } else {
                        activeAlert = .selectTransaction
                    }
                }) {
                    Image(systemName: "square.and.pencil")
                }
                Button(action: {
                    if selected != nil {
                        activeAlert = .confirmDelete
                    } else {
                        activeAlert = .selectTransaction
                    }
                }) {
                    Image(systemName: "trash")
                }
            }.padding()
            Spacer()
            Picker("View As", selection: $selectedView) {
                ForEach(TransactionViewType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            Text("\(selected?.memo ?? "None")")
        }.sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .new:
                TransactionForm(title: "New Transaction", onSubmit: updateTransaction, onCancel: {activeSheet = nil}).padding()
            case .edit:
                TransactionForm(title: "Edit Transaction", transaction: selected!,
                                onSubmit: updateTransaction, onCancel: {activeSheet = nil})
                .padding()
            }
        }.alert(item: $activeAlert) { alert in
            switch alert {
            case .deleteFail:
                return Alert(
                    title: Text("Database Error"),
                    message: Text("Failed to delete transaction"),
                    dismissButton: .default(Text("OK"))
                )
            case .selectTransaction:
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
                        deleteTransaction(selected!.id!)
                    })
                )
            }
        }
        
        switch selectedView {
        case .List: ListTransactionsView(query: query, selection: $selected).onAppear(perform: {print("list appear")})
        case .Table: Text("Table View")
        case .Calendar: Text("Calendar View")
        }
    }
    
    func updateTransaction(_ data: inout Transaction){
        print(data)
        do {
            try database!.saveTransaction(&data)
            activeSheet = nil
        } catch {
            print(error)
        }
    }
    
    func deleteTransaction(_ id: Int64){
        do {
            try database!.deleteTransactions(ids: [id])
            activeSheet = nil
        } catch {
            print(error)
        }
    }
    
}

enum ActiveSheet : String, Identifiable { // <--- note that it's now Identifiable
    case new, edit
    
    var id: String { return self.rawValue }
}

enum ActiveAlert : String, Identifiable { // <--- note that it's now Identifiable
    case deleteFail, selectTransaction, confirmDelete
    
    var id: String { return self.rawValue }
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
