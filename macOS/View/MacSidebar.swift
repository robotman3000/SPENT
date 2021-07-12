//
//  MacSidebar.swift
//  macOS
//
//  Created by Eric Nims on 6/8/21.
//

import SwiftUI

struct MacSidebar: View {
    
    @EnvironmentObject var store: DatabaseStore
    @State private var showingAlert = false
    @State private var selectedView: Int? = 0
    @State var selectedBucket: Bucket?
    @State var contextSelectedBucket: Bucket?
    
    var body: some View {
        VStack {
            Text("SPENT Git Version:")
            let version: String = Bundle.main.object(forInfoDictionaryKey: "GIT_COMMIT_HASH").debugDescription
            Text(version)
            QueryWrapperView(source: BucketBalanceRequest(selectedBucket)) { balance in
                BalanceTable(/*name: selectedBucket?.name ?? "None",*/
                             posted: balance.posted,
                             available: balance.available,
                             postedInTree: balance.postedInTree,
                             availableInTree: balance.availableInTree)
            }
            List(selection: $selectedBucket) {
                NavigationLink(destination: MacHome(), tag: 0, selection: self.$selectedView) {
                    Label("Summary", systemImage: "house")
                }
                
                Section(header: Text("Accounts")){
                    OutlineGroup(store.bucketTree, id: \.bucket, children: \.children) { node in
                        NavigationLink(destination: MacTransactionView(selectedBucket: node.bucket)) {
                            QueryWrapperView(source: BucketBalanceRequest(node.bucket)) { balance in
                                BucketRow(name: node.bucket.name, balance: balance.postedInTree)
                            }
                        }
                        .contextMenu {
                            Button("Edit") {
                                contextSelectedBucket = node.bucket
                            }
                        }
                    }
                }.collapsible(false)
            }.listStyle(SidebarListStyle())
        }
        .sheet(item: $contextSelectedBucket) { bucket in
            BucketForm(bucket: bucket, onSubmit: {data in
                store.updateBucket(&data, onComplete: dismissModal, onError: { _ in showingAlert.toggle() })
            }, onCancel: dismissModal).padding()
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Database Error"),
                message: Text("Failed to delete account"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onDeleteCommand {
            store.deleteBucket(selectedBucket!.id!, onComplete: dismissModal, onError: { _ in showingAlert.toggle() })
        }
        .toolbar(){
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar, label: {
                    Image(systemName: "sidebar.left")
                })
            }
        }
    }
    
    func dismissModal(){
        contextSelectedBucket = nil
        showingAlert = false
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

struct MacSidebar_Previews: PreviewProvider {
    static var previews: some View {
        MacSidebar()
    }
}
