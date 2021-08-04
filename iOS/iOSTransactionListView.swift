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
    @State var showingEditor: Bool = false
    @State var selection: TransactionData?
    @EnvironmentObject var appState: GlobalState
    
    var body: some View {
        QueryWrapperView(source: TransactionModelRequest(
                            TransactionFilter(includeTree: appState.includeTree,
                                              bucket: bucket),
                                              order: appState.sorting,
                                              direction: appState.sortDirection)){ model in
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
                        NavigationLink(destination: TransactionView(status: item.transaction.status,
                                                                    direction: item.transaction.type,
                                                                    contextDirection: item.transaction.getType(convertTransfer: true, bucket: bucket.id!),
                                                                    date: item.transaction.date,
                                                                    posted: item.transaction.posted,
                                                                    sourceName: item.source?.name ?? "",
                                                                    destinationName: item.destination?.name ?? "",
                                                                    amount: item.transaction.amount,
                                                                    payee: item.transaction.payee,
                                                                    memo: item.transaction.memo,
                                                                    tags: item.tags)){
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
            .toolbar(content: {
                ToolbarItem(placement: .primaryAction){
                    Menu {
                        Button(action: {//TODO: Show form}) {
                            Label("Edit Account", systemImage: "gear")
                        }
                    } label: { Label("Menu", systemImage: "ellipsis.circle") }
                }
            }).sheet(isPresented: $showingEditor){
                Text("")
            }
        }
    }
}
