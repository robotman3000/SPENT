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
    @Environment(\.appDatabase) private var database: AppDatabase?
    
    let transactions: [Transaction]
    let bucketName: String
    
    @State var editTags = false
    @Binding var selection: Transaction?
    
    var body: some View {
        List(selection: $selection){
            if !transactions.isEmpty {
                ForEach(transactions, id:\.self ){ item in
                    //TODO: Implement support for split transactions
                    //TODO: Implement support for tags
                    //TODO: Calculate this outside the view and pass in
                    let sourceName = database!.getBucketFromID(item.sourceID)?.name ?? "NIL"
                    let destName = database!.getBucketFromID(item.destID)?.name ?? "NIL"
                    TransactionRow(status: item.status, direction: item.type, date: item.date, sourceName: sourceName, destinationName: destName, amount: item.amount, payee: item.payee, memo: item.memo).frame(height: 55)
                }
            } else {
                Text("No Transactions")
            }
        }.navigationTitle(bucketName)
        .contextMenu(ContextMenu(menuItems: {
            Button("Edit Tags"){
                if selection != nil {
                    editTags.toggle()
                }
            }
        }))
        //.sheet(isPresented: $editTags, content: {
//            TransactionTagForm(transaction: selection!, tags: Set(transactionTags[selection!] ?? []), onSubmit: {tags, transaction in
//                print(tags)
//                if selection != nil {
//                    store.setTransactionTags(transaction: selection!, tags: tags)
//                }
//                editTags.toggle()
//            }, onCancel: {editTags.toggle()})
//        })
    }
}

struct ListTransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        ListTransactionsView(transactions: [], bucketName: "A bucket", selection: Binding<Transaction?>(get: { return nil }, set: {_ in}))
    }
}
