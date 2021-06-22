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
    
    init(query: TransactionRequest, selection: Binding<Transaction?>){
        self._transactions = Query(query)
        self._selection = selection
    }
    
    var body: some View {
        if !transactions.isEmpty {
            Section(header:
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
            ){}
            //var rowColor = false
            //    .background(rowColor.flipFlop() ? Color.white.saturation(1) : Color.red.saturation(0.1))
            List(transactions, id:\.self, selection: $selection){ item in
                
                //ForEach(){ item in
                    TableRow(content: [
                        AnyView(TableCell {
                            Text(item.status.getStringName())
                        }),
                        AnyView(TableCell {
                            Text(item.date.transactionFormat)
                        }),
                        AnyView(TableCell {
                            Text(item.posted?.transactionFormat ?? "N/A")
                        }),
                        AnyView(TableCell {
                            Text(item.amount.currencyFormat)
                        }),
                        AnyView(TableCell {
                            Text("\(item.sourceID ?? -1)")
                        }),
                        AnyView(TableCell {
                            Text("\(item.destID ?? -1)")
                        }),
                        AnyView(TableCell {
                            Text(item.memo)
                        }),
                        AnyView(TableCell {
                            Text(item.payee ?? "N/A")
                        }),
                        AnyView(TableCell {
                            Text(item.group?.uuidString ?? "N/A")
                        })
                    ]).frame(height: 20)
                //}
            }.listStyle(PlainListStyle()).listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        } else {
            Text("No Transactions")
        }
    }
}

//struct TableTransactionsView_Previews: PreviewProvider {
//    static var previews: some View {
//        TableTransactionsView()
//    }
//}
