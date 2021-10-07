//
//  TransactionList.swift
//  macOS
//
//  Created by Eric Nims on 9/2/21.
//

import SwiftUI
import SwiftUIKit

struct TransactionList: View {
    @EnvironmentObject var appState: GlobalState
    @Binding var selected: Set<TransactionData>
    let selectedBucket: Bucket
    let model: [TransactionData]
    @ObservedObject var context: SheetContext
    @ObservedObject var aContext: AlertContext
    
    var body: some View {
        if !model.isEmpty {
            List(model, id: \.self, selection: $selected){ item in
                TransactionRow(transactionData: item, showTags: appState.showTags, showMemo: appState.showMemo, showRunning: selectedBucket.parentID == nil && appState.sorting == .byDate)
                    .frame(height: appState.showMemo || appState.showTags ? 48 : 24)
                .contextMenu {
                    TransactionContextMenu(context: context, aContext: aContext, contextBucket: selectedBucket, transactions: selected.contains(item) ? selected : [item], onFormDismiss: {
                        selected.removeAll()
                    })
                }
            }.listStyle(.plain)
        } else {
            List{
                Text("No Transactions")
            }
        }
    }
}

//struct TransactionList_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionList()
//    }
//}
