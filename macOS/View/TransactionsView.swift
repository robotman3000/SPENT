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
    @State var stringFilter: String = ""
    let forBucket: Bucket
    @StateObject private var context = SheetContext()
    @StateObject private var aContext = AlertContext()
    
    var body: some View {
        VStack {
            HStack {
                Toggle(isOn: $appState.includeTree, label: { Text("Show All Transactions") })
                Toggle(isOn: $appState.showTags, label: { Text("Show Tags") })
                Toggle(isOn: $appState.showInTree, label: { Text("Show Local Transfers") })
                Spacer()
                EnumPicker(label: "Sort By", selection: $appState.sorting, enumCases: TransactionFilter.Ordering.allCases)
                EnumPicker(label: "", selection: $appState.sortDirection, enumCases: TransactionFilter.OrderDirection.allCases).pickerStyle(SegmentedPickerStyle())
                TextField("", text: $stringFilter)
                Spacer(minLength: 15)
            }.padding()
            
            QueryWrapperView(source: TransactionModelRequest(withFilter: TransactionFilter(includeTree: appState.includeTree, showInTree: appState.showInTree, bucket: forBucket, textFilter: stringFilter))){ model in
                SortingWrapperView(agent: TransactionDataSortingAgent(order: appState.sorting, orderDirection: appState.sortDirection), input: model){ data in
                    TransactionList(selected: $selected, selectedBucket: forBucket, model: data, context: context, aContext: aContext).contextMenu {
                        _NewTransactionContextButtons(context: context, aContext: aContext, contextBucket: forBucket, onFormDismiss: { context.dismiss() })
                    }
                    
                    HStack(alignment: .firstTextBaseline) {
                        Spacer()
                        Text("\(model.count) transactions")
                        Spacer()
                        Text("Showing matches for: \(stringFilter)")
                    }.padding().frame(height: 30)
                }
            }
        }.navigationTitle(forBucket.name).sheet(context: context).alert(context: aContext)
    }
}

//struct MacTransactionView_Previews: PreviewProvider {
//    static var previews: some View {
//        MacTransactionView()
//    }
//}
