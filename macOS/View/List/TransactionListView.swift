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
    @State var selected = Set<Int64>()
    let ids: [Int64]
    let contextBucket: Int64?
    
    var body: some View {
        List(selection: $selected) {
            if ids.isEmpty {
                    Text("No Transactions")
            }
            
            ForEach(ids, id: \.self){ transactionID in
                TransactionListRow(forID: transactionID)
                .contextMenu {
                    AsyncContentView(source: TransactionFilter.publisher(store.getReader(), forID: transactionID)){ model in
                        TransactionContextMenu(context: sheetContext, aContext: alertContext, contextBucket: contextBucket, forTransactions: selected, forTransaction: model, onFormDismiss: {})
                    }
                }
            }
        }
        .contextMenu {
            TransactionContextMenu(context: sheetContext, aContext: alertContext, contextBucket: contextBucket, forTransactions: selected, forTransaction: nil, onFormDismiss: {})
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
