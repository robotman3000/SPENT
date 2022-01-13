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
    @State var editTags = false
    @State var stringFilter: String = ""
    let forBucketID: Int64?
    let isAccount: Bool
    @StateObject private var context = SheetContext()
    @StateObject private var aContext = AlertContext()
    
    @State var showViewOptions: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Button("View Options"){
                    showViewOptions.toggle()
                }.popover(isPresented: $showViewOptions){
                    VStack(alignment: .leading){
                        Toggle(isOn: $appState.includeTree, label: { Text("Show All Transactions") })
                        Toggle(isOn: $appState.showTags, label: { Text("Show Tags") })
                        Toggle(isOn: $appState.showMemo, label: { Text("Show Memo") })
                        Toggle(isOn: $appState.showInTree, label: { Text("Show Local Transfers") })
                    }.padding()
                }
                Spacer()
                EnumPicker(label: "Sort By", selection: $appState.sorting, enumCases: TransactionFilter.Ordering.allCases)
                EnumPicker(label: "", selection: $appState.sortDirection, enumCases: TransactionFilter.OrderDirection.allCases).pickerStyle(SegmentedPickerStyle())
                TextField("", text: $stringFilter)
                Spacer(minLength: 15)
            }.padding()

            QueryWrapperView(source: TransactionFilter(forBucket: forBucketID, includeBucketTree: appState.includeTree, showAllocations: appState.showInTree, memoLike: stringFilter, ordering: appState.sorting, direction: appState.sortDirection)){ transactionIDs in
                TransactionListView(ids: transactionIDs, contextBucket: forBucketID, isAccount: isAccount)
                
                VStack {
                    Spacer()
                    HStack(alignment: .center) {
                        Spacer()
                        Text("\(transactionIDs.count) transactions")
                        Spacer()
                        if !stringFilter.isEmpty {
                            Text("Showing matches for: \(stringFilter)")
                        }
                    }
                    Spacer()
                }.frame(height: 30)
            }
        }//.navigationTitle(forBucketID ?? "All Transactions").sheet(context: context).alert(context: aContext)
    }
}

//struct MacTransactionView_Previews: PreviewProvider {
//    static var previews: some View {
//        MacTransactionView()
//    }
//}
