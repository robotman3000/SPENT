//
//  TransactionListView.swift
//  macOS
//
//  Created by Eric Nims on 10/19/21.
//

import SwiftUI
import SwiftUIKit

struct TransactionListView: View {
    @EnvironmentObject var store: DatabaseStore
    @StateObject var sheetContext: SheetContext = SheetContext()
    @StateObject var alertContext: AlertContext = AlertContext()
    let ids: [Int64]
    let contextBucket: Bucket
    
    var body: some View {
        List(ids, id: \.self){ transactionID in
            TransactionListRow(forID: transactionID)
            .contextMenu {
                AsyncContentView(source: TTransactionFilter.publisher(store.getReader(), forID: transactionID)){ model in
                    TransactionContextMenu(context: sheetContext, aContext: alertContext, contextBucket: contextBucket, forTransaction: model, onFormDismiss: {})
                }
            }
            
            /*
             TransactionRow(transactionData: item, showTags: appState.showTags, showMemo: appState.showMemo, showRunning: selectedBucket.parentID == nil && appState.sorting == .byDate)
                 .frame(height: appState.showMemo || appState.showTags ? 48 : 24)
             .contextMenu {
                 TransactionContextMenu(context: context, aContext: aContext, contextBucket: selectedBucket, transactions: selected.contains(item) ? selected : [item], onFormDismiss: {
                     selected.removeAll()
                 })
             }
             */
        }
        .contextMenu {
            TransactionContextMenu(context: sheetContext, aContext: alertContext, contextBucket: contextBucket, forTransaction: nil, onFormDismiss: {})
        }
        .sheet(context: sheetContext)
        .alert(context: alertContext)
    }
}

//struct TransactionListView_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionListView()
//    }
//}
