//
//  TransactionSplitTable.swift
//  macOS
//
//  Created by Eric Nims on 7/29/21.
//

import SwiftUI
import SwiftUIKit

struct SplitTransactionMemberList: View {
    
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
                }){}
            
            
            List(splits, id: \.self, selection: $selected){ split in
                QueryWrapperView(source: SingleBucketRequest(id: (splitDirection == .Deposit ? split.destID : split.sourceID)!)){ bucket in
                    Row(bucketName: bucket?.name ?? "Error", amount: split.amount, memo: split.memo).tag(split).height(32)
                }
            }
        }.popover(item: $selected) { transaction in
            QueryWrapperView(source: BucketRequest()){ buckets in
                SplitMemberForm(transaction: transaction,
                                bucketChoices: buckets,
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
                
            }
            
        }.sheet(context: context).alert(context: aContext)
    }
    
    struct Row: View {
        let bucketName: String
        let amount: Int
        let memo: String
        
        var body: some View {
            HStack(alignment: .center){
                VStack (alignment: .leading) {
                    HStack{
                        Text(bucketName)
                        Spacer()
                    }
                    HStack{
                        Text(amount.currencyFormat).bold()
                        Spacer()
                    }
                }.frame(width: 150)
                Text(memo).help(memo)
                Spacer()
            }
        }
    }
}

struct TransactionSplitTable_Previews: PreviewProvider {
    static var previews: some View {
        //TransactionSplitTable()
        SplitTransactionMemberList.Row(bucketName: "Preview Bucket", amount: 3756, memo: "Some relevant memo goes here")
    }
}
