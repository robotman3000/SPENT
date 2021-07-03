//
//  TableTransactionsView.swift
//  SPENT
//
//  Created by Eric Nims on 6/18/21.
//

import SwiftUI

struct TableTransactionsView: View {
    
    let transactions: [TransactionData]
    let bucketName: String
    let bucketID: Int64?
    
    @Binding var selection: TransactionData?
    
    var body: some View {
        VStack{
            Section(header: Header()){}
            if !transactions.isEmpty {
                List(transactions, id:\.self, selection: $selection){ item in
                    Row(status: item.transaction.status,
                    direction: item.transaction.type,
                    date: item.transaction.date,
                    postDate: item.transaction.posted,
                    sourceName: item.source?.name ?? "",
                    destinationName: item.destination?.name ?? "",
                    amount: item.transaction.amount,
                    payee: item.transaction.payee,
                    memo: item.transaction.memo,
                    group: item.transaction.group
                    ).frame(height: 20)
                }.listStyle(PlainListStyle()).listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            } else {
                List{
                    Text("No Transactions")
                }
            }
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
        let status: Transaction.StatusTypes
        let direction: Transaction.TransType
        let date: Date
        let postDate: Date?
        let sourceName: String
        let destinationName: String
        let amount: Int
        let payee: String?
        let memo: String
        let group: UUID?
        
        var body: some View {
            TableRow(content: [
                AnyView(TableCell {
                    Text(status.getStringName())
                }),
                AnyView(TableCell {
                    Text(date.transactionFormat)
                }),
                AnyView(TableCell {
                    Text(postDate?.transactionFormat ?? "N/A")
                }),
                AnyView(TableCell {
                    Text(amount.currencyFormat)
                        .foregroundColor(direction == .Withdrawal ? .red : .gray)
                }),
                AnyView(TableCell {
                    Text(sourceName)
                }),
                AnyView(TableCell {
                    Text(destinationName)
                }),
                AnyView(TableCell {
                    Text(memo)
                }),
                AnyView(TableCell {
                    Text(payee ?? "N/A")
                }),
                AnyView(TableCell {
                    Text(group?.uuidString ?? "N/A")
                })
            ])
        }
    }
}

struct TableTransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        let bucket1 = Bucket(id: 1, name: "Account 1", parentID: nil, ancestorID: nil, memo: "", budgetID: nil)
        TableTransactionsView(transactions: [], bucketName: bucket1.name, bucketID: bucket1.id!, selection: Binding<TransactionData?>(get: { return nil }, set: {_ in}))
    }
}
