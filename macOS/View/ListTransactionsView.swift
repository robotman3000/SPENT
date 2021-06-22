//
//  TransactionsView.swift
//  macOS
//
//  Created by Eric Nims on 4/16/21.
//

import SwiftUI
import GRDB

struct ListTransactionsView: View {
    @Query<TransactionRequest> var transactions: [Transaction]
    @Binding var selection: Transaction?
    @Binding var bucket: Bucket?
    
    init(query: TransactionRequest, selection: Binding<Transaction?>, bucket: Binding<Bucket?>){
        self._transactions = Query(query)
        self._selection = selection
        self._bucket = bucket
    }
    
    var body: some View {
        if !transactions.isEmpty {
            List(selection: $selection){
                ForEach(transactions, id:\.self ){ item in
                    //Text(item.memo).frame(height: 30)
                    TransactionRow(transaction: item, bucket: bucket!).frame(height: 55)
                }
            }
        } else {
            Text("No Transactions")
        }
    }
}

//struct TransactionsView_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionsView()
//    }
//}
