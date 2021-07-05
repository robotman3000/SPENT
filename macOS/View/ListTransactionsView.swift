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

    let transactions: [TransactionData]
    let bucketName: String
    let bucketID: Int64?
    
    @State var editTags = false
    @Binding var selection: TransactionData?
    
    var body: some View {
        List(selection: $selection){
            if !transactions.isEmpty {
                ForEach(transactions, id:\.self ){ item in
                    //TODO: Implement support for split transactions
                    TransactionRow(status: item.transaction.status,
                                   direction: item.transaction.type,
                                   contextDirection: item.transaction.getType(convertTransfer: true, bucket: bucketID),
                                   date: item.transaction.date,
                                   sourceName: item.source?.name ?? "",
                                   destinationName: item.destination?.name ?? "",
                                   amount: item.transaction.amount,
                                   payee: item.transaction.payee,
                                   memo: item.transaction.memo,
                                   tags: item.tags)
                        .frame(height: 55)
                        .contextMenu(ContextMenu(menuItems: {
                            Button("Edit Tags"){
                                if selection != nil {
                                    editTags.toggle()
                                }
                            }
                        }))
                }
            } else {
                Text("No Transactions")
            }
        }.navigationTitle(bucketName)
        .sheet(isPresented: $editTags, content: {
            TransactionTagForm(transaction: selection!.transaction, tags: Set(selection!.tags), onSubmit: {tags, transaction in
                print(tags)
                if selection != nil {
                    store.setTransactionTags(transaction: selection!.transaction, tags: tags)
                }
                editTags.toggle()
            }, onCancel: {editTags.toggle()})
        })
    }
}

struct ListTransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        ListTransactionsView(transactions: [], bucketName: "A bucket", bucketID: nil, selection: Binding<TransactionData?>(get: { return nil }, set: {_ in}))
    }
}