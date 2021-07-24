//
//  TableTransactionsView.swift
//  SPENT
//
//  Created by Eric Nims on 6/18/21.
//

import SwiftUI
import SwiftUIKit

struct TableTransactionsView: View {
    let transactions: [TransactionData]
    let bucket: Bucket
    
    @Binding var selection: Set<TransactionData>
    @ObservedObject var context: SheetContext
    @ObservedObject var aContext: AlertContext
    @EnvironmentObject var store: DatabaseStore
    @EnvironmentObject var appState: GlobalState
    
    var body: some View {
        VStack{
            Section(header: Header()){}
            if !transactions.isEmpty {
                List(transactions, id:\.self, selection: $selection){ item in
                    VStack(spacing: 0){
                        Row(status: item.transaction.status,
                        direction: item.transaction.type,
                        cdirection: item.transaction.getType(convertTransfer: true, bucket: bucket.id),
                        date: item.transaction.date,
                        postDate: item.transaction.posted,
                        sourceName: item.source?.name ?? "",
                        destinationName: item.destination?.name ?? "",
                        amount: item.transaction.amount,
                        payee: item.transaction.payee,
                        memo: item.transaction.memo,
                        group: item.transaction.group,
                        tags: item.tags,
                        showTags: $appState.showTags)
                    }.frame(height: (appState.showTags ? 60 : 20)).listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))//.background(Color.black)
//                    .contentShape(Rectangle())
//                    .gesture(TapGesture(count: 1).onEnded { _ in
//                        if item.transaction.type == .Transfer {
//                            context.present(UIForms.transfer(context: context, transaction: item.transaction, contextBucket: bucket, onSubmit: {data in
//                                store.updateTransaction(&data, onComplete: { context.dismiss() })
//                            }))
//                        } else {
//                            context.present(UIForms.transaction(context: context, transaction: item.transaction, contextBucket: bucket, onSubmit: {data in
//                                store.updateTransaction(&data, onComplete: { context.dismiss() })
//                            }))
//                        }
//                    })
                    .contextMenu{
                        TransactionContextMenu(context: context, aContext: aContext, contextBucket: bucket, transactions: selection.contains(item) ? selection : [item])
                    }
                }.listStyle(PlainListStyle())
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
            ], showDivider: false)
        }
    }
    
    struct Row: View {
        let status: Transaction.StatusTypes
        let direction: Transaction.TransType
        let cdirection: Transaction.TransType
        let date: Date
        let postDate: Date?
        let sourceName: String
        let destinationName: String
        let amount: Int
        let payee: String?
        let memo: String
        let group: UUID?
        let tags: [Tag]
        
        @Binding var showTags: Bool
        
        var body: some View {
            VStack (alignment: .leading){
                HStack(alignment: .center){
                    status.getIconView().frame(width: 20, height: 20)
                    Text(payee ?? direction.getStringName()).frame(maxWidth: .infinity)
                    Text(postDate?.transactionFormat ?? date.transactionFormat).frame(maxWidth: .infinity)
                    TransactionRow.Direction(sourceName: sourceName, destinationName: destinationName, direction: direction, contextDirection: cdirection).frame(maxWidth: .infinity)
                    Text(amount.currencyFormat).foregroundColor(cdirection == .Withdrawal ? .red : .gray).frame(maxWidth: .infinity)
                    Text(memo).frame(maxWidth: .infinity)
                }
                if showTags {
                    HStack{
                        ForEach(tags, id: \.self){ tag in
                            TransactionRow.Badge(text: tag.name, color: .gray)
                        }
                    }
                }
                Spacer(minLength: 5)
                Divider()
            }
//            TableRow(content: [
//                AnyView(TableCell {
//                    Text(status.getStringName())
//                }),
//                AnyView(TableCell {
//                    Text(date.transactionFormat)
//                }),
//                AnyView(TableCell {
//                    Text(postDate?.transactionFormat ?? "N/A")
//                }),
//                AnyView(TableCell {
//                    Text(amount.currencyFormat)
//                        .foregroundColor(direction == .Withdrawal ? .red : .gray)
//                }),
//                AnyView(TableCell {
//                    Text(sourceName)
//                }),
//                AnyView(TableCell {
//                    Text(destinationName)
//                }),
//                AnyView(TableCell {
//                    Text(memo)
//                }),
//                AnyView(TableCell {
//                    Text(payee ?? "N/A")
//                }),
//                AnyView(TableCell {
//                    Text(group?.uuidString ?? "N/A")
//                })
//            ])
        }
    }
}
//
//struct TableTransactionsView_Previews: PreviewProvider {
//    static var previews: some View {
//        let bucket1 = Bucket(id: 1, name: "Account 1", parentID: nil, ancestorID: nil, memo: "", budgetID: nil)
//        TableTransactionsView(transactions: [], bucketName: bucket1.name, bucketID: bucket1.id!, selection: Binding<TransactionData?>(get: { return nil }, set: {_ in}))
//    }
//}
