//
//  MainView.swift
//  macOS
//
//  Created by Eric Nims on 8/26/21.
//

import SwiftUI
import SwiftUIKit

struct MainView: View {
    @State private var selectedView: Int? = 0
    @State var selectedBucket: Bucket?
    
    @EnvironmentObject private var store: DatabaseStore
    @StateObject private var context = SheetContext()
    @StateObject private var aContext = AlertContext()
    
    var body: some View {
        NavigationView {
            VStack {
                QueryWrapperView(source: BucketBalanceRequest(selectedBucket)) { balance in
                    BalanceTable(name: selectedBucket?.name ?? "NIL",
                                 posted: balance.posted,
                                 available: balance.available,
                                 postedInTree: balance.postedInTree,
                                 availableInTree: balance.availableInTree,
                                 isNIL: selectedBucket == nil)
                }
                List(selection: $selectedBucket) {
                    NavigationLink(destination: HomeView(), tag: 0, selection: $selectedView) {
                        Label("Summary", systemImage: "house")
                    }
                    
                    Section(header: Text("Accounts")){
                        QueryWrapperView(source: BucketRequest(order: .byTree)){ accounts in
                            if !accounts.isEmpty {
                                OutlineGroup(DatabaseStore.getBucketTree(treeList: accounts), id: \.bucket, children: \.children) { node in
                                    NavigationLink(destination: TransactionsView(forBucket: node.bucket)) {
                                        QueryWrapperView(source: BucketBalanceRequest(node.bucket)) { balance in
                                            BucketRow(name: node.bucket.name, balance: balance.postedInTree)
                                        }
                                    }.contextMenu {
                                        AccountContextMenu(context: context, aContext: aContext, contextAccount: node.bucket)
                                    }
                                }
                            } else {
                                Text("No Accounts")
                            }
                        }
                    }.collapsible(false)
                }.listStyle(SidebarListStyle())
                .contextMenu{
                    Button("New Account"){
                        context.present(FormKeys.account(context: context, account: nil, onSubmit: {data in
                            store.updateBucket(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                        }))
                    }
                }
            }
            .sheet(context: context)
            .alert(context: aContext)
            .toolbar(){
                ToolbarItem(placement: .navigation) {
                    Button(action: toggleSidebar, label: {
                        Image(systemName: "sidebar.left")
                    })
                }
            }
            .frame(minWidth: 300)
            .navigationTitle("Accounts")
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

//struct MainView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainView()
//    }
//}
