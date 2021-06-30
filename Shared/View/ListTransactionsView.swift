//
//  TransactionsView.swift
//  macOS
//
//  Created by Eric Nims on 4/16/21.
//

import SwiftUI
import GRDB

struct ListTransactionsView: View {
    @EnvironmentObject var store: DatabaseStore
    var transactions: [Transaction] = []
    var transactionTags: [Transaction : [Tag]]
    @State var editTags = false
    #if os(macOS)
    @Binding var selection: Transaction?
    #else
    @State var selection: Transaction?
    #endif
    var bucket: Bucket?
    
    var body: some View {
        List(selection: $selection){
            if !transactions.isEmpty {
                ForEach(transactions, id:\.self ){ item in
                    TransactionRow(transaction: item, bucket: bucket!, tags: getTags(item)).frame(height: 55)
                }
            } else {
                Text("No Transactions")
            }
        }.navigationTitle(bucket?.name ?? "No Name")
        .contextMenu(ContextMenu(menuItems: {
            Button("Edit Tags"){
                editTags.toggle()
            }
        })).sheet(isPresented: $editTags, content: {
            if selection == nil {
                EmptyView().onAppear(perform: {
                    editTags = false
                })
            } else {
                TransactionTagForm(transaction: selection!, tags: Set(transactionTags[selection!] ?? []), onSubmit: {tags, transaction in
                    print(tags)
                    if selection != nil {
                        store.setTransactionTags(transaction: selection!, tags: tags)
                    }
                    editTags.toggle()
                }, onCancel: {editTags.toggle()})
            }
        })
    }
    
    func getTags(_ transaction: Transaction) -> [Tag]? {
        var result = transactionTags[transaction]
        if result == nil {
            return nil
        }
        return result
    }
}

//struct TransactionsView_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionsView()
//    }
//}
