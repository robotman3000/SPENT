//
//  TransactionSplitTable.swift
//  macOS
//
//  Created by Eric Nims on 7/29/21.
//

import SwiftUI
import SwiftUIKit

struct TransactionSplitTable: View {
    
    @EnvironmentObject fileprivate var store: DatabaseStore
    @StateObject private var context = SheetContext()
    @StateObject private var aContext = AlertContext()
    
    let head: Transaction
    @Binding var splits: [Transaction]
    let splitDirection: Transaction.TransType
    @State fileprivate var selected: Transaction?

    var body: some View {
        VStack{
            Section(header:
                VStack {
                    HStack {
                        Button(action: {
                            let member = Transaction.newSplitMember(head: head)
                            splits.append(member)
                            selected = splits.last!
                        }) {
                            Image(systemName: "plus")
                        }
                        Spacer()
                    }
                    Header()
                }){}
            
            
            List(splits, id: \.self, selection: $selected){ split in
                Row(bucketName: store.getBucketByID(splitDirection == .Deposit ? split.destID : split.sourceID)?.name ?? "Error", amount: split.amount, memo: split.memo).tag(split)
            }
        }.popover(item: $selected) { transaction in
            SplitMemberForm(transaction: transaction,
                            bucketChoices: store.buckets,
                            splitDirection: splitDirection,
                            onSubmit: {data in
                                var sindex = -1
                                
                                for index in splits.indices {
                                    if splits[index] == selected {
                                        sindex = index
                                        break;
                                    }
                                }
                                
                                if sindex != -1 {
                                    splits[sindex] = data
                                }
                                selected = nil
                            },
                            onDelete: {
                                var dindex = -1
                                
                                for index in splits.indices {
                                    if splits[index] == selected {
                                        dindex = index
                                        break;
                                    }
                                }
                                
                                if dindex != -1 {
                                    splits.remove(at: dindex)
                                }
                                selected = nil
                            },
                            onCancel: { selected = nil }).padding()
            
        }.sheet(context: context).alert(context: aContext)
    }
    
    struct Header: View {
        var body: some View {
            TableRow(content: [
                AnyView(TableCell {
                    Text("Bucket")
                }),
                AnyView(TableCell {
                    Text("Amount")
                }),
                AnyView(TableCell {
                    Text("Memo")
                })
            ], showDivider: false)
        }
    }
    
    struct Row: View {
        
        //TODO: This should really be a binding
        let bucketName: String
        let amount: Int
        let memo: String
        
        var body: some View {
            TableRow(content: [
                AnyView(TableCell {
                    Text(bucketName)
                }),
                AnyView(TableCell {
                    Text(amount.currencyFormat)
                }),
                AnyView(TableCell {
                    Text(memo.trunc(length: 10)).help(memo)
                })
            ], showDivider: false)
        }
    }
}

//struct TransactionSplitTable_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionSplitTable()
//    }
//}
