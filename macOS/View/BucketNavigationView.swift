//
//  BucketListView.swift
//  SPENT
//
//  Created by Eric Nims on 10/16/21.
//

import SwiftUI
import SwiftUIKit

struct BucketNavigationView: View {
    @StateObject var sheetContext: SheetContext = SheetContext()
    @StateObject var alertContext: AlertContext = AlertContext()
    @EnvironmentObject var store: DatabaseStore
    
    let ids: [Int64]
    @Binding var selection: Int64?
    
    var body: some View {
        List{
            NavigationLink(destination: TransactionsView(forBucketID: nil), tag: -1, selection: $selection) {
                Label("All Transactions", systemImage: "list.triangle")
            }
            Section(header: Text("Accounts")){
                if !ids.isEmpty {
                    ForEach(ids, id: \.self) { bucketID in
                        NavigationLink(destination: TransactionsView(forBucketID: bucketID), tag: bucketID, selection: $selection) {
                            BucketListRow(id: bucketID)
                        }
                        .contextMenu {
                            AsyncContentView(source: BucketFilter.publisher(store.getReader(), forID: bucketID)){ bucketModel in
                                AccountContextMenu(context: sheetContext, aContext: alertContext, model: bucketModel)
                            }
                        }
                    }
                } else {
                    Text("No Accounts")
                }
            }.collapsible(false)
        }.listStyle(SidebarListStyle())
        .sheet(context: sheetContext)
        .alert(context: alertContext)
        .contextMenu{
            AccountContextMenu(context: sheetContext, aContext: alertContext, model: nil)
        }
    }
}

//struct BucketListView_Previews: PreviewProvider {
//    static var previews: some View {
//        BucketListView()
//    }
//}
