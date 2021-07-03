//
//  TableTransactionsView.swift
//  SPENT
//
//  Created by Eric Nims on 6/18/21.
//

import SwiftUI

struct TableTransactionsView: View {
    
    var transactions: [Transaction]
    var bucket: Bucket
    @Binding var selection: Transaction?
    
    @Environment(\.appDatabase) private var database: AppDatabase?
    
    var body: some View {
        VStack{
            Section(header: Header()){}
            if !transactions.isEmpty {
                List(transactions, id:\.self, selection: $selection){ item in
                    //TODO: Calculate this outside the view and pass in
                    let sourceName = database!.getBucketFromID(item.sourceID)?.name ?? "NIL"
                    let destName = database!.getBucketFromID(item.destID)?.name ?? "NIL"
                    let direction = item.getType(convertTransfer: true, bucket: bucket.id!)
                    
                    Row(status: item.status, direction: direction, date: item.date, postDate: item.posted, sourceName: sourceName, destinationName: destName, amount: item.amount, payee: item.payee, memo: item.memo, group: item.group).frame(height: 20)
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
        TableTransactionsView(transactions: [], bucket: bucket1, selection: Binding<Transaction?>(get: { return nil }, set: {_ in}))
    }
}
