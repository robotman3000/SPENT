//
//  MacTransactionView.swift
//  macOS
//
//  Created by Eric Nims on 6/18/21.
//

import SwiftUI
import SwiftUIKit
import GRDB

struct TransactionListView: View {
    @EnvironmentObject var appState: GlobalState
    @EnvironmentObject var store: DatabaseStore
    @State var selected: Set<TransactionData> = Set<TransactionData>()
    let selectedBucket: Bucket
    @State var editTags = false
    @State var contextSelection: TransactionData?
    
    @StateObject private var context = SheetContext()
    @StateObject private var aContext = AlertContext()
    
    var body: some View {
        VStack {
            HStack {
                Toggle(isOn: $appState.includeTree, label: { Text("Show All Transactions") })
                Toggle(isOn: $appState.showTags, label: { Text("Show Tags") })
                Spacer()
                EnumPicker(label: "Sort By", selection: $appState.sorting, enumCases: TransactionModelRequest.Ordering.allCases)
                EnumPicker(label: "", selection: $appState.sortDirection, enumCases: TransactionModelRequest.OrderDirection.allCases).pickerStyle(SegmentedPickerStyle())
                Spacer(minLength: 15)
            }.padding()
            
            QueryWrapperView(source: TransactionModelRequest(
                                TransactionFilter(includeTree: appState.includeTree,
                                                  bucket: selectedBucket),
                                                  order: appState.sorting,
                                                  direction: appState.sortDirection)){ model in
                
                VStack{
                    if !model.isEmpty {
                        List(model, id:\.self, selection: $contextSelection){ item in
                            VStack(spacing: 0){
                                TransactionRow(status: item.transaction.status,
                                direction: item.transaction.type,
                                cdirection: item.transaction.getType(convertTransfer: true, bucket: selectedBucket.id),
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
                                cBucket: selectedBucket,
                                showTags: $appState.showTags)
                            }.frame(height: (appState.showTags ? 64 : 32)).listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .contextMenu {
                                TransactionContextMenu(context: context, aContext: aContext, contextBucket: selectedBucket, transactions: selected.contains(item) ? selected : [item], onFormDismiss: {
                                    selected.removeAll()
                                })
                            }
                        }.listStyle(PlainListStyle())
                    } else {
                        List{
                            Text("No Transactions")
                        }
                    }
                }.contextMenu {
                    _NewTransactionContextButtons(context: context, aContext: aContext, contextBucket: selectedBucket, onFormDismiss: { context.dismiss() })
                }
                
                HStack(alignment: .firstTextBaseline) {
                    Button(action: {
                        context.present(FormKeys.transaction(context: context, transaction: nil, contextBucket: selectedBucket, bucketChoices: store.buckets, onSubmit: {data in
                            store.updateTransaction(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                        }))
                    }) {
                        Image(systemName: "plus")
                    }
                    Spacer()
                    Text("\(model.count) transactions")
                    Spacer()
                }.padding().frame(height: 30)
            }
        }.navigationTitle(selectedBucket.name).sheet(context: context).alert(context: aContext)
    }
}

//struct MacTransactionView_Previews: PreviewProvider {
//    static var previews: some View {
//        MacTransactionView()
//    }
//}
