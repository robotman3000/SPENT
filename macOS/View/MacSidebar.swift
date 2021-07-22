//
//  MacSidebar.swift
//  macOS
//
//  Created by Eric Nims on 6/8/21.
//

import SwiftUI

struct MacSidebar: View {
    
    let bucketTree: [BucketNode]
    @State private var selectedView: Int? = 0
    @State var selectedBucket: Bucket?
    
    var body: some View {
        VStack {
            let version: String = (Bundle.main.object(forInfoDictionaryKey: "GIT_COMMIT_HASH") as! String?) ?? "(NIL)"
            Text("SPENT Git Version: \(version)")
            QueryWrapperView(source: BucketBalanceRequest(selectedBucket)) { balance in
                BalanceTable(posted: balance.posted,
                             available: balance.available,
                             postedInTree: balance.postedInTree,
                             availableInTree: balance.availableInTree)
            }
            List(selection: $selectedBucket) {
                NavigationLink(destination: MacHome(), tag: 0, selection: $selectedView) {
                    Label("Summary", systemImage: "house")
                }
                
                Section(header: Text("Accounts")){
                    OutlineGroup(bucketTree, id: \.bucket, children: \.children) { node in
                        NavigationLink(destination: MacTransactionView(selectedBucket: node.bucket)) {
                            QueryWrapperView(source: BucketBalanceRequest(node.bucket)) { balance in
                                BucketRow(name: node.bucket.name, balance: balance.postedInTree)
                            }
                        }.contextMenu {
                            AccountContextMenu()
                        }
                    }
                }.collapsible(false)
            }.listStyle(SidebarListStyle())
            .contextMenu{
                Button("New Account"){
                    
                }
            }
        }
        .toolbar(){
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar, label: {
                    Image(systemName: "sidebar.left")
                })
            }
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

struct AccountContextMenu: View {
    var body: some View {
        Button("New Account"){
            
        }

        Button("Edit Account"){
            
        }
        
        Button("Delete Account"){
            
        }

        Divider()
        
        Button("Add Bucket"){
            
        }
    
        Divider()
        
        Button("Add Transaction"){
            
        }
        
        Button("Make Transfer"){
            
        }
    }
}

struct MacSidebar_Previews: PreviewProvider {
    static var previews: some View {
        MacSidebar(bucketTree: [], selectedBucket: nil)
    }
}
