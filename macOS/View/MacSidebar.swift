//
//  MacSidebar.swift
//  macOS
//
//  Created by Eric Nims on 6/8/21.
//

import SwiftUI
import SwiftUIKit
import Foundation

struct MacSidebar: View {
    
    @Binding var bucketTree: [BucketNode]
    let schedules: [Schedule]
    let tags: [Tag]
    @State private var selectedView: Int? = 0
    @State var selectedBucket: Bucket?
    
    @EnvironmentObject private var store: DatabaseStore
    @StateObject private var context = SheetContext()
    @StateObject private var aContext = AlertContext()
    
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
                
                NavigationLink(destination: TagTable(tags: tags)) {
                    Label("Tags", systemImage: "tag")
                }
                
                //TODO: Design and implement a proper schedule manager
                NavigationLink(destination: ScheduleTable(schedules: schedules)) {
                    Label("Schedules", systemImage: "calendar.badge.clock")
                }
                
                Section(header: Text("Accounts")){
                    if !store.accounts.isEmpty {
                        OutlineGroup(bucketTree, id: \.bucket, children: \.children) { node in
                            NavigationLink(destination: MacTransactionView(selectedBucket: node.bucket)) {
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
                }.collapsible(false)
            }.listStyle(SidebarListStyle())
            .contextMenu{
                Button("New Account"){
                    context.present(UIForms.account(context: context, account: nil, onSubmit: {data in
                        store.updateBucket(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
                    }))
                }
            }
        }.sheet(context: context).alert(context: aContext)
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
    @ObservedObject var context: SheetContext
    @ObservedObject var aContext: AlertContext
    @State var contextAccount: Bucket
    @EnvironmentObject private var store: DatabaseStore
    
    var body: some View {
        Button("New Account"){
            context.present(UIForms.account(context: context, account: nil, onSubmit: {data in
                store.updateBucket(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
            }))
        }
        
        if(contextAccount.ancestorID == nil){
            Button("Edit Account"){
                context.present(UIForms.account(context: context, account: contextAccount, onSubmit: {data in
                    store.updateBucket(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
                }))
            }
            
            Button("Delete Account"){
                context.present(UIForms.confirmDelete(context: context, message: "", onConfirm: {
                    store.deleteBucket(contextAccount.id!, onError: {error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription )) })
                }))
            }
            
            Divider()
            
            Button("Add Bucket"){
                context.present(UIForms.accountBucket(context: context, contextAccount: contextAccount, parentChoices: store.accounts, budgetChoices: store.schedules, onSubmit: {data in
                    store.updateBucket(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
                }))
            }
        } else {
            Button("Edit Bucket"){
                context.present(UIForms.bucket(context: context, bucket: contextAccount, parentChoices: store.accounts, budgetChoices: store.schedules, onSubmit: {data in
                    store.updateBucket(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
                }))
            }
            
            Button("Delete Bucket"){
                context.present(UIForms.confirmDelete(context: context, message: "", onConfirm: {
                    store.deleteBucket(contextAccount.id!, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
                }))
            }
        }
    
        Divider()
        
        Button("Add Transaction"){
            context.present(UIForms.transaction(context: context, transaction: nil, contextBucket: contextAccount, onSubmit: {data in
                store.updateTransaction(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
            }))
        }
        
        Button("Add Transfer"){
            context.present(UIForms.transfer(context: context, transaction: nil, contextBucket: contextAccount, sourceChoices: store.buckets, destChoices: store.buckets, onSubmit: {data in
                store.updateTransaction(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
            }))
        }
    }
}

//struct MacSidebar_Previews: PreviewProvider {
//    static var previews: some View {
//        MacSidebar(bucketTree: [], schedules: [], tags: [], selectedBucket: nil)
//    }
//}
