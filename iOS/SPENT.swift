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
    
    //@State var isActive: Bool = false
    @StateObject var globalState: GlobalState = GlobalState()
    @StateObject var sheetContext: SheetContext = SheetContext()
    @StateObject var alertContext: AlertContext = AlertContext()
    
    var body: some Scene {
        DocumentGroup(newDocument: SPENTDatabaseDocument()){ file in
            Text(file.document.manager.database.path)
            MainView()
                .sheet(context: sheetContext)
                .alert(context: alertContext)
                .environmentObject(globalState)
                .environmentObject(file.document.manager)
                .environment(\.dbQueue, file.document.manager.database)
                //.frame(minWidth: 1000, minHeight: 600)
        }
    }
}

struct MainView: View {
    @StateObject var sheetContext = SheetContext()
    @StateObject var alertContext = AlertContext()
    @Query(AllAccounts(), in: \.dbQueue) var accounts: [AccountInfo]
    
    @State var selection: Account?
    
    var body: some View {
        NavigationView {
            VStack {
                List{
                    Section(header: Text("Accounts")){
                        ForEachEnumerated(accounts) { accountInfo in
                            NavigationLink(destination: AccountTransactionsView(forAccount: accountInfo.account, withBucket: nil), tag: accountInfo.account, selection: $selection){
                                HStack{
                                    AccountListRow(model: accountInfo)
                                }
                            }
                        }
                        
                        if accounts.count == 0 {
                            Text("No Accounts")
                        }
                    }
                }
            }
        }
    }
}

struct AccountTransactionsView: View {
    @EnvironmentObject var globalState: GlobalState
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
        }
        
    }
}

import GRDB
private struct TransactionsList: View {
    @Environment(\.dbQueue) var queue: DatabaseQueue
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
        Text(queue.path)
        List (selection: $selection){
            ForEachEnumerated(transactions){ transactionInfo in
                
                    //TransactionListRow(model: transactionInfo, showRunning: showRunningBalance, showEntryDate: showEntryDate, rowMode: , enableHighlight: highlightRows)
                Text(transactionInfo.transaction.memo)
                    .tag(transactionInfo.transaction)
            }
        }
    }
}
