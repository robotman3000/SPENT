//
//  TransactionsView.swift
//  macOS
//
//  Created by Eric Nims on 4/16/21.
//

import SwiftUI
import SwiftUIKit
import GRDB

struct ListTransactionsView: View {
    @EnvironmentObject var store: DatabaseStore

    let transactions: [TransactionData]
    let bucket: Bucket
    
    @Binding var selection: Set<TransactionData>
    @ObservedObject var context: SheetContext
    @ObservedObject var aContext: AlertContext
    
    
    var body: some View {
        List(selection: $selection){
            if !transactions.isEmpty {
                ForEach(transactions, id:\.self ){ item in
                    //TODO: Implement support for split transactions
                    TransactionRow(status: item.transaction.status,
                                   direction: item.transaction.type,
                                   contextDirection: item.transaction.getType(convertTransfer: true, bucket: bucket.id!),
                                   date: item.transaction.date,
                                   sourceName: item.source?.name ?? "",
                                   destinationName: item.destination?.name ?? "",
                                   amount: item.transaction.amount,
                                   payee: item.transaction.payee,
                                   memo: item.transaction.memo,
                                   tags: item.tags)
                        .frame(height: 55)
                        .contextMenu{
                            TransactionContextMenu(context: context, aContext: aContext, contextBucket: bucket, transactions: [item])
                        }
                }
            } else {
                Text("No Transactions")
            }
        }
    }
}
//
//struct ListTransactionsView_Previews: PreviewProvider {
//    static var previews: some View {
//        ListTransactionsView(transactions: [], bucketName: "A bucket", bucketID: nil, selection: Binding<TransactionData?>(get: { return nil }, set: {_ in}))
//    }
//}
