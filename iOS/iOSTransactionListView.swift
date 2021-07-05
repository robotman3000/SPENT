//
//  iOSTransactionView.swift
//  iOS
//
//  Created by Eric Nims on 6/24/21.
//

import Foundation
import SwiftUI

struct iOSTransactionListView: View {
    let bucket: Bucket
    @State var selection: TransactionData?
    
    var body: some View {
        QueryWrapperView(source: TransactionModelRequest(TransactionFilter(includeTree: (bucket.ancestorID == nil), bucket: bucket))){ model in
            List(selection: $selection){
                QueryWrapperView(source: BucketBalanceRequest(bucket)) { balance in
                    BalanceTable(/*name: selectedBucket?.name ?? "None",*/
                                 posted: balance.posted,
                                 available: balance.available,
                                 postedInTree: balance.postedInTree,
                                 availableInTree: balance.availableInTree)
                }
                
                if !model.isEmpty {
                    ForEach(model, id:\.self ){ item in
                        //TODO: Implement support for split transactions
                        NavigationLink(destination: TransactionView(data: item)){
                            TransactionRow(status: item.transaction.status,
                                           direction: item.transaction.type,
                                           contextDirection: item.transaction.getType(convertTransfer: true, bucket: bucket.id),
                                           date: item.transaction.date,
                                           sourceName: item.source?.name ?? "",
                                           destinationName: item.destination?.name ?? "",
                                           amount: item.transaction.amount,
                                           payee: item.transaction.payee,
                                           memo: item.transaction.memo,
                                           tags: item.tags)
                                .frame(height: 55)
                        }.isDetailLink(true)
                    }
                } else {
                    Text("No Transactions")
                }
            }.navigationTitle(bucket.name)
        }
    }
}
