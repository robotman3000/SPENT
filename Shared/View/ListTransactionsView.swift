//
//  TransactionsView.swift
//  macOS
//
//  Created by Eric Nims on 4/16/21.
//

import SwiftUI
import GRDB

struct ListTransactionsView: View {
    var transactions: [Transaction] = []
    var transactionTags: [Int64 : [Tag]] = [:]
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
                    TransactionRow(transaction: item, bucket: bucket!, tags: transactionTags[item.id!] ?? []).frame(height: 55)
                }
            } else {
                Text("No Transactions")
            }
        }.navigationTitle(bucket?.name ?? "No Name")
    }
}

//struct TransactionsView_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionsView()
//    }
//}
