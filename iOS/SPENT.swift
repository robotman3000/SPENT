//
//  SPENTApp.swift
//  SPENT
//
//  Created by Eric Nims on 3/30/21.
//

import SwiftUI
import SwiftUIKit
import GRDBQuery

@main
struct SPENT: App {
    static var DB_VERSION: Int64 = 6
    
    var body: some Scene {
        DocumentGroup(newDocument: SPENTDatabaseDocument()){ file in
            MainView()
                .environmentObject(file.document.manager)
                .environment(\.dbQueue, file.document.manager.database)
        }
    }
}

struct MainView: View {
    var body: some View {
        NavigationView {
            List{
                AccountsList()
            }
        }.navigationTitle("Accounts")
    }
}
struct AccountsList: View {
    @EnvironmentObject var dbManager: DatabaseManager
    @StateObject var sheetContext = SheetContext()
    @StateObject var alertContext = AlertContext()
    
    @Query(AllAccounts(), in: \.dbQueue) var accounts: [AccountInfo]
    
    @State var selection: Account?
    
    var body: some View {
        Section (){
            ForEachEnumerated(accounts) { accountInfo in
                NavigationLink(destination: AccountTransactionsView(forAccount: accountInfo.account, withBucket: nil)
                    .environment(\.dbQueue, dbManager.database),
                               tag: accountInfo.account, selection: $selection){
                    HStack{
                        AccountListRow(model: accountInfo)
                    }
                }.contextMenu {
                    Button("Delete Account"){
                        dbManager.action(DeleteAccountAction(account: accountInfo.account))
                    }
                }
            }
            
            if accounts.count == 0 {
                Text("No Accounts")
            }
        }.toolbar {
            ToolbarItem {
                Button(action: {
                    sheetContext.present(FormKeys.account(context: sheetContext, account: nil))
                }) {
                    Image(systemName: "plus")
                }
            }
        }.sheet(context: sheetContext)
        .alert(context: alertContext)
    }
}

struct AccountTransactionsView: View {
    @EnvironmentObject var globalState: GlobalState
    @StateObject var sheetContext = SheetContext()
    @StateObject var alertContext = AlertContext()
    let account: Account
    let bucket: Bucket?
    
    init(forAccount: Account, withBucket: Bucket?){
        self.account = forAccount
        self.bucket = withBucket
    }
    
    var body: some View {
        Section {
            AccountBalanceView(forAccount: account)
            TransactionsList(forAccount: account, forBucket: nil, orderBy: .byPostDate, orderDirection: .ascending)
        }.navigationTitle(account.name)
        .toolbar {
            ToolbarItem {
                Menu {
                    Section{
                        Button(action: {
                            //print("Create Transaction")
                            sheetContext.present(FormKeys.transaction(context: sheetContext, transaction: nil))
                        }) {
                            Text("Add Transaction")
                            Image(systemName: "plus")
                        }
                        Button(action: {
                            print("Create Transaction")
                            //context.present(FormKeys.account(context: context, account: nil))
                        }) {
                            Text("Add Transfer")
                            Image(systemName: "plus")
                        }
                    }
                    
                    Button(action: {
                        print("Create Acount")
                        //context.present(FormKeys.account(context: context, account: nil))
                    }) {
                        Text("Filter")
                        Image(systemName: "line.3.horizontal.circle")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.circle")
               }
            }
        }
        .sheet(context: sheetContext)
        .alert(context: alertContext)
    }
}

import GRDB
private struct TransactionsList: View {
    @Query<AccountTransactions> var transactions: [TransactionInfo]
    @State var selection = Set<Transaction>()
    let showRunningBalance: Bool
    let showEntryDate: Bool
    let highlightRows = UserDefaults.standard.bool(forKey: PreferenceKeys.highlightRowsByStatus.rawValue)
    
    init(forAccount: Account, forBucket: Bucket?, showAllocations: Bool = true, showCleared: Bool = true, orderBy: Transaction.Ordering, orderDirection: Transaction.OrderDirection){
        selection = Set<Transaction>()
        
        self._transactions = Query(AccountTransactions(account: forAccount, bucket: forBucket, excludeAllocations: !showAllocations, excludeCleared: !showCleared, direction: orderDirection, ordering: orderBy), in: \.dbQueue)
        self.showRunningBalance = forBucket == nil && orderBy == .byPostDate
        self.showEntryDate = orderBy == .byEntryDate
    }
    
    var body: some View {
        List (selection: $selection){
            ForEachEnumerated(transactions){ transactionInfo in
                
                    //TransactionListRow(model: transactionInfo, showRunning: showRunningBalance, showEntryDate: showEntryDate, rowMode: , enableHighlight: highlightRows)
                Text(transactionInfo.transaction.memo)
                    .tag(transactionInfo.transaction)
            }
        }.listStyle(.plain)
    }
}
