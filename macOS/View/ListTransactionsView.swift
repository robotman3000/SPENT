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
    
    init(query: TransactionRequest, selection: Binding<Transaction?>){
        self._transactions = Query(query)
        self._selection = selection
    }
    
    var body: some View {
        if !transactions.isEmpty {
            List(selection: $selection){
                ForEach(transactions, id:\.self ){ item in
                    TransactionRow(transaction: item)
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
