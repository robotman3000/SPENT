//
//  MacTransactionView.swift
//  macOS
//
//  Created by Eric Nims on 6/18/21.
//

import SwiftUI
import SwiftUIKit
import GRDB

struct TransactionsView: View {
    @EnvironmentObject var appState: GlobalState
    @EnvironmentObject var store: DatabaseStore
    @State var selected: Set<TransactionData> = Set<TransactionData>()
    @State var editTags = false
    let forBucket: Bucket
    @StateObject private var context = SheetContext()
    @StateObject private var aContext = AlertContext()
    
//    init(forBucket: Bucket){
//        self.filter = TransactionFilter(forBucket, $appState.includeTree)
//    }
    
    var body: some View {
        VStack {
            HStack {
                Toggle(isOn: $appState.includeTree, label: { Text("Show All Transactions") })
                Toggle(isOn: $appState.showTags, label: { Text("Show Tags") })
                Spacer()
                EnumPicker(label: "Sort By", selection: $appState.sorting, enumCases: TransactionFilter.Ordering.allCases)
                EnumPicker(label: "", selection: $appState.sortDirection, enumCases: TransactionFilter.OrderDirection.allCases).pickerStyle(SegmentedPickerStyle())
                Spacer(minLength: 15)
            }.padding()
            
            QueryWrapperView(source: TransactionModelRequest(withFilter: TransactionFilter(includeTree: appState.includeTree, bucket: forBucket, order: appState.sorting, orderDirection: appState.sortDirection))){ model in
                
                TransactionList(selected: $selected, selectedBucket: forBucket, model: model, context: context, aContext: aContext).contextMenu {
                    _NewTransactionContextButtons(context: context, aContext: aContext, contextBucket: forBucket, onFormDismiss: { context.dismiss() })
                }
                
                HStack(alignment: .firstTextBaseline) {
//                    Button(action: {
//                        context.present(FormKeys.transaction(context: context, transaction: nil, contextBucket: forBucket, bucketChoices: store.buckets, onSubmit: {data in
//                            store.updateTransaction(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
//                        }))
//                    }) {
//                        Image(systemName: "plus")
//                    }
                    Spacer()
                    Text("\(model.count) transactions")
                    Spacer()
                }.padding().frame(height: 30)
            }
        }.navigationTitle(forBucket.name).sheet(context: context).alert(context: aContext)
    }
}

//struct MacTransactionView_Previews: PreviewProvider {
//    static var previews: some View {
//        MacTransactionView()
//    }
//}
