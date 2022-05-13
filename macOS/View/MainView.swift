//
//  MainView.swift
//  macOS
//
//  Created by Eric Nims on 8/26/21.
//

import SwiftUI
import SwiftUIKit
import GRDBQuery
import GRDB

struct MainView: View {
    @StateObject var sheetContext = SheetContext()
    @StateObject var alertContext = AlertContext()
    @Query(AllAccounts(), in: \.dbQueue) var accounts: [AccountInfo]
    @State var selection: Account?
    
    var body: some View {
        NavigationView {
            VStack {
                Section {
                    if let account = selection {
                        AccountBalanceView(forAccount: account)
                    } else {
                        Text("Select an account")
                    }
                }
                List {
                    Section(header: Text("Accounts")){
                        ForEachEnumerated(accounts) { accountInfo in
                            NavigationLink(destination: AccountBucketsListView(forAccount: accountInfo.account), tag: accountInfo.account, selection: $selection){
                                AccountListRow(model: accountInfo)
                            }.contextMenu { AccountContextMenu(context: sheetContext, aContext: alertContext, forAccount: accountInfo.account) }
                        }
                    }.collapsible(false)
                }.listStyle(SidebarListStyle())
                .contextMenu {
                    Button("New Account"){
                        sheetContext.present(FormKeys.account(context: sheetContext, account: nil))
                    }
                }
            }.toolbar(){
                ToolbarItem(placement: .navigation) {
                    Button(action: toggleSidebar, label: {
                        Image(systemName: "sidebar.left")
                    })
                }
            }
            .alert(context: alertContext)
            .sheet(context: sheetContext)
            .frame(minWidth: 300)
            .navigationTitle("Accounts")
            
            EmptyView()
            
            if let account = selection {
                AccountTransactionsView(forAccount: account, withBucket: nil)
            } else {
                EmptyView()
            }
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
    
    private func newAccountClick() {
        sheetContext.present(FormKeys.account(context: sheetContext, account: nil))
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        // Empty list
        MainView().environment(\.dbQueue, SPENTDatabaseDocument.emptyDatabaseQueue())

        // Non-empty list
        MainView().environment(\.dbQueue, SPENTDatabaseDocument.populatedDatabaseQueue())
    }
}
