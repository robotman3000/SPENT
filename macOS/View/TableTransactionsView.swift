//
//  TableTransactionsView.swift
//  SPENT
//
//  Created by Eric Nims on 6/18/21.
//

import SwiftUI

struct TableTransactionsView: View {
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
            Section(header: Header()){}
            List(transactions, id:\.self, selection: $selection){ item in
                Row(transaction: item, bucket: bucket!).frame(height: 20)
            }.listStyle(PlainListStyle()).listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        } else {
            Text("No Transactions")
        }
    }
    
    struct Header: View {
        var body: some View {
            TableRow(content: [
                AnyView(TableCell {
                    Text("Staus")
                }),
                AnyView(TableCell {
                    Text("Date")
                }),
                AnyView(TableCell {
                    Text("Post Date")
                }),
                AnyView(TableCell {
                    Text("Amount")
                }),
                AnyView(TableCell {
                    Text("Source Bucket")
                }),
                AnyView(TableCell {
                    Text("Dest Bucket")
                }),
                AnyView(TableCell {
                    Text("Memo")
                }),
                AnyView(TableCell {
                    Text("Payee")
                }),
                AnyView(TableCell {
                    Text("Group ID")
                })
            ])
        }
    }
    
    struct Row: View {
        
        @State var transaction: Transaction
        @State var bucket: Bucket
        
        var body: some View {
            TableRow(content: [
                AnyView(TableCell {
                    Text(transaction.status.getStringName())
                }),
                AnyView(TableCell {
                    Text(transaction.date.transactionFormat)
                }),
                AnyView(TableCell {
                    Text(transaction.posted?.transactionFormat ?? "N/A")
                }),
                AnyView(TableCell {
                    Text(transaction.amount.currencyFormat)
                        .foregroundColor(transaction.getType(convertTransfer: true, bucket: bucket.id!) == .Withdrawal ? .red : .gray)
                }),
                AnyView(TableCell {
                    Text("\(transaction.sourceID ?? -1)")
                }),
                AnyView(TableCell {
                    Text("\(transaction.destID ?? -1)")
                }),
                AnyView(TableCell {
                    Text(transaction.memo)
                }),
                AnyView(TableCell {
                    Text(transaction.payee ?? "N/A")
                }),
                AnyView(TableCell {
                    Text(transaction.group?.uuidString ?? "N/A")
                })
            ])
        }
    }
}

//struct TableTransactionsView_Previews: PreviewProvider {
//    static var previews: some View {
//        TableTransactionsView()
//    }
//}
