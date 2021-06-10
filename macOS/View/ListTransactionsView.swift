//
//  TransactionsView.swift
//  macOS
//
//  Created by Eric Nims on 4/16/21.
//

import SwiftUI
import GRDB

struct ListTransactionsView: View {
    let title: String
    @Query<TransactionRequest> private var transactions: [Transaction]
    @EnvironmentObject var stateController: StateController
    @State private var showingAlert = false
    @State private var showingForm = false
    @State var selectedIndex: Int?
    @State var editIndex: Int?
    
    init(query: TransactionRequest, title: String){
        //print("init trans list")
        self._transactions = Query(query)
        self.title = title
    }
    
//    init(_ title: String, query: QueryInterfaceRequest<Transaction>){
//        self._transactions = Query(ObservedQuery(query: query))
//        self.title = title
//    }
    
    var body: some View {
        Text("\(selectedIndex ?? -1)")
        if !transactions.isEmpty {
            List(selection: $selectedIndex){
                ForEach(Array(transactions.enumerated()), id: \.offset){ item in
                    TransactionRow(transaction: item.element)
                        .contextMenu {
                            Button("Edit") {
                                selectedIndex = item.offset
                                showingForm.toggle()
                            }
                            Button("Delete") {
    
                            }
                        }
                }
            }.onDeleteCommand {
                do {
                    if selectedIndex != nil {
                        try stateController.database.deleteTransactions(ids: [transactions[selectedIndex!].id!])
                    }
                    selectedIndex = nil
                } catch {
                    showingAlert.toggle()
                }
            }
            .sheet(isPresented: $showingForm) {
                TransactionForm(title: "Edit Transaction", transaction: transactions[selectedIndex!], onSubmit: updateTransaction, onCancel: {showingForm.toggle()})
                .padding()
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Database Error"),
                    message: Text("Failed to delete transaction"),
                    dismissButton: .default(Text("OK"))
                )
            }
        } else {
            Text("No Transactions")
        }
        //Text("\(selectedID ?? -1)")
//        List(selection: $selectedID) {
//            if !transactions.isEmpty {
//                //.sorted(by: { $0.TransDate >= $1.TransDate })
//                ForEach(Array(transactions.enumerated()), id: \.element) { index, transaction in
//                    TransactionRow(transaction: transaction).onHover(perform: { hovered in
////                        if hovered {
////                            print("Index: \(selectedIndex)")
////                            selectedIndex = index
////                            print("Index2: \(selectedIndex)")
////                        }
//                    }).contextMenu {
//                        Button("Edit") {
//                            showingForm.toggle()
//                        }
//                        Button("Delete") {
//
//                        }
//                    }//.frame(height: 30)
//                }
//            } else {
//                Text("No Transactions")
//            }
//        }.listStyle(PlainListStyle()).navigationTitle(title)
//        .sheet(isPresented: $showingForm) {
//            TransactionForm(title: "Edit Transaction", transaction: transactions[selectedIndex], onSubmit: updateTransaction, onCancel: {showingForm.toggle()})
//            .padding()
//        }
//        .alert(isPresented: $showingAlert) {
//            Alert(
//                title: Text("Database Error"),
//                message: Text("Failed to delete tag"),
//                dismissButton: .default(Text("OK"))
//            )
//        }
    }
    
    func updateTransaction(_ data: inout Transaction){
        print(data)
        do {
            try stateController.database.saveTransaction(&data)
            showingForm.toggle()
        } catch {
            print(error)
        }
    }
    
    func deleteTransaction(indexSet: IndexSet) {
        for i in indexSet {
            print(i)
            //accounts.remove(at: i)
        }
    }
}

//struct TransactionsView_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionsView()
//    }
//}
