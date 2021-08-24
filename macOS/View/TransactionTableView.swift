//
//  TableTransactionsView.swift
//  SPENT
//
//  Created by Eric Nims on 6/18/21.
//

import SwiftUI
import SwiftUIKit

struct TransactionTableView: View {
    let transactions: [TransactionData]
    let bucket: Bucket
    
    @Binding var selection: Set<TransactionData>
    @ObservedObject var context: SheetContext
    @ObservedObject var aContext: AlertContext
    @EnvironmentObject var store: DatabaseStore
    @EnvironmentObject var appState: GlobalState
    
    var body: some View {
        VStack{
            //Section(header: Header()){}
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
                        splits: item.splitMembers,
                        cBucket: bucket,
                        showTags: $appState.showTags)
                    }.frame(height: (appState.showTags ? 64 : 32)).listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .contextMenu {
                        TransactionContextMenu(context: context, aContext: aContext, contextBucket: bucket, transactions: selection.contains(item) ? selection : [item], onFormDismiss: {
                            selection.removeAll()
                        })
                    }
                }.listStyle(PlainListStyle())
            } else {
                List{
                    Text("No Transactions")
                }
            }
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
        let splits: [Transaction]
        let cBucket: Bucket
        
        @Binding var showTags: Bool
        
        var body: some View {
            VStack (alignment: .leading){
                HStack(alignment: .center){
                    //TODO: This should be split into two views
                    Spacer(minLength: 2)
                    status.getIconView().frame(width: 16, height: 16)
                    
                    VStack{
                        Text(payee ?? direction.getStringName())
                        Text(postDate?.transactionFormat ?? date.transactionFormat)
                    }.width(150)
                    
                    Spacer()
                    VStack{
                        if group == nil {
                            Text(amount.currencyFormat).foregroundColor(cdirection == .Withdrawal ? .red : .gray)
                            TransactionRow.Direction(sourceName: sourceName, destinationName: destinationName, direction: direction, contextDirection: cdirection)
                        } else {
                            Text("Split \(Transaction.getSplitDirection(members: splits).getStringName())")
                            HStack{
                                if let trans = Transaction.getSplitMember(splits, bucket: cBucket) {
                                    Text("(\(trans.amount.currencyFormat))").foregroundColor(Transaction.getSplitDirection(members: splits) == .Withdrawal ? .red : .gray)
                                }
                                Text(Transaction.amountSum(splits).currencyFormat).foregroundColor(Transaction.getSplitDirection(members: splits) == .Withdrawal ? .red : .gray)
                            }
                        }
                    }.width(200)
                    
                    
                    
                    Text(memo).frame(maxWidth: .infinity).help(memo)
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
