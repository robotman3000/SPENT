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
    
    let ids: [BucketTreeNode]
    @Binding var selection: Int64?
    
    var body: some View {
       List(selection: $selection) {
//          NavigationLink(destination: TransactionsView(forBucketID: nil, isAccount: false), tag: -1, selection: $selection) {
//              Label("All Transactions", systemImage: "list.triangle")
//          }
          Section(header: Text("Accounts")){
              if !ids.isEmpty {
                 OutlineGroup(ids, id: \.id, children: \.children){ bucketNode in
                    NavigationLink(destination: TransactionsView(forBucketID: bucketNode.id, isAccount: bucketNode.isAccount).environmentObject(store), tag: bucketNode.id, selection: $selection) {
                       BucketListRow(id: bucketNode.id)
                    }.contextMenu {
                       AsyncContentView(source: BucketFilter.publisher(store.getReader(), forID: bucketNode.id), "BucketNavigationView [Context]"){ bucketModel in
                          AccountContextMenu(context: sheetContext, aContext: alertContext, model: bucketModel)
                       }
                    }
                 }
              } else {
                  Text("No Accounts")
              }
          }.collapsible(false)
       }
       .listStyle(SidebarListStyle())
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
