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
            List(selection: $selected){
                ForEach(model, id:\.self){ item in
                    VStack(spacing: 0){
                        TransactionRow(transactionData: item, contextBucket: selectedBucket, showTags: $appState.showTags)
                        //Text(item.transaction.memo)
                    }.frame(height: (appState.showTags ? 64 : 32)).listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .contextMenu {
                        TransactionContextMenu(context: context, aContext: aContext, contextBucket: selectedBucket, transactions: selected.contains(item) ? selected : [item], onFormDismiss: {
                            selected.removeAll()
                        })
                    }
                }//.id(UUID())
            }.listStyle(PlainListStyle())
            
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
