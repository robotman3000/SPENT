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
    @Binding var selection: Transaction?
    var bucket: Bucket?
    
    var body: some View {
        Text(bucket?.name ?? "No Name")
        List(selection: $selection){
            if !transactions.isEmpty {
                ForEach(transactions, id:\.self ){ item in
                    TransactionRow(transaction: item, bucket: bucket!).frame(height: 55)
                }
            } else {
                Text("No Transactions")
            }
        }
    }
}

//struct TransactionsView_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionsView()
//    }
//}
