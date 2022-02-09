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
                            NavigationLink(destination: AccountTransactionsView(forAccount: accountInfo.account), tag: accountInfo.account, selection: $selection){
                                AccountRow(forAccount: accountInfo)
                            }.contextMenu { AccountContextMenu(sheet: sheetContext, forAccount: accountInfo.account) }
                        }
                    }.collapsible(false)
                }.listStyle(SidebarListStyle())
            }.toolbar(){
                ToolbarItem(placement: .navigation) {
                    Button(action: toggleSidebar, label: {
                        Image(systemName: "sidebar.left")
                    })
                }
                ToolbarItem(placement: .automatic) {
                    Button(action: newAccountClick, label: {
                        Text("New Account")
                    })
                }
            }
            .frame(minWidth: 300)
            .navigationTitle("Accounts")
        }.sheet(context: sheetContext)
        .alert(context: alertContext)
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
    
    private func newAccountClick() {
        sheetContext.present(FormKeys.account(context: sheetContext, account: nil))
    }
}

struct AccountRow: View {
    let forAccount: AccountInfo
    
    var body: some View {
        HStack {
            Text(forAccount.account.name)
            Spacer()
            Text(forAccount.balance.posted.currencyFormat)
        }
    }
}

struct AccountContextMenu: View {
    @EnvironmentObject var databaseManager: DatabaseManager
    @ObservedObject var sheet: SheetContext
    let forAccount: Account
    
    var body: some View {
        Button("Edit account") {
            sheet.present(FormKeys.account(context: sheet, account: forAccount))
        }
        Button("Delete \(forAccount.name)") {
            databaseManager.action(.deleteAccount(forAccount), onSuccess: {
                print("deleted account successfully")
            })
        }
    }
}

struct TransactionRow: View {
    let forTransaction: TransactionInfo
    
    var body: some View {
        HStack {
            Text(forTransaction.transaction.status.getStringName())
            Text(forTransaction.transaction.amount.currencyFormat)
            Text(forTransaction.transaction.entryDate.transactionFormat)
            Text(forTransaction.transaction.postDate?.transactionFormat ?? "N/A")
            Text(forTransaction.transaction.payee)
            Text(forTransaction.transaction.memo)
            Text(forTransaction.bucket?.name ?? "No Bucket")
            Text(forTransaction.account.name)
            Text(forTransaction.runningBalance.runningBalance.currencyFormat)
        }
    }
}

struct TransactionContextMenu: View {
    @EnvironmentObject var databaseManager: DatabaseManager
    @ObservedObject var sheet: SheetContext
    let forTransaction: Transaction
    
    var body: some View {
        Button("Edit transaction") {
            sheet.present(FormKeys.transaction(context: sheet, transaction: forTransaction))
        }
        Button("Delete transaction") {
            databaseManager.action(.deleteTransaction(forTransaction), onSuccess: {
                print("deleted transaction successfully")
            })
        }
    }
}

struct AccountTransactionsView: View {
    @StateObject var sheetContext = SheetContext()
    let account: Account
    @Query<AccountTransactions> var transactions: [TransactionInfo]
    @State var selection: Transaction?
    
    init(forAccount: Account){
        self._transactions = Query(AccountTransactions(account: forAccount, bucket: nil), in: \.dbQueue)
        self.account = forAccount
    }
    
    var body: some View {
        Text("\(selection?.id! ?? -1)")
        List (selection: $selection){
            ForEachEnumerated(transactions){ transactionInfo in
                TransactionRow(forTransaction: transactionInfo)
                    .contextMenu { TransactionContextMenu(sheet: sheetContext, forTransaction: transactionInfo.transaction) }.tag(transactionInfo.transaction)
            }
        }.toolbar {
            ToolbarItem(placement: .automatic){
                Button(action: newTransactionClick, label: {
                    Text("New Transaction")
                })
            }
        }.sheet(context: sheetContext)
    }
    
    private func newTransactionClick() {
        sheetContext.present(FormKeys.transaction(context: sheetContext, transaction: nil))
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

// Database structs
struct AccountBalance: Decodable, FetchableRecord, TableRecord {
    let id: Int64
    let posted: Int
    let available: Int
    let allocatable: Int
    
//    static let account = belongsTo(Account.self)
//    static var databaseTableName: String = "AccountBalance"
}

// Swift View specific database structs
struct AccountInfo: Decodable, FetchableRecord {
    var account: Account
    var balance: AccountBalance
}

extension AccountInfo {
    /// The request for all account infos
    static func all() -> AdaptedFetchRequest<SQLRequest<AccountInfo>> {
        let request: SQLRequest<AccountInfo> = """
            SELECT
                \(columnsOf: Account.self),
                \(columnsOf: AccountBalance.self)
            FROM Accounts
            LEFT JOIN AccountBalance USING (id)
            """
        return request.adapted { db in
            let adapters = try splittingRowAdapters(columnCounts: [
                Account.numberOfSelectedColumns(db),
                AccountBalance.numberOfSelectedColumns(db)])
            return ScopeAdapter([
                CodingKeys.account.stringValue: adapters[0],
                CodingKeys.balance.stringValue: adapters[1]])
        }
    }

    /// Fetches all account infos
    static func fetchAll(_ db: Database) throws -> [AccountInfo] {
        try all().fetchAll(db)
    }
}

struct AccountRunningBalance: Decodable, FetchableRecord, TableRecord {
    let runningBalance: Int
    let accountID: Int64
    let transactionID: Int64
}

struct TransactionInfo: Decodable, FetchableRecord {
    var transaction: Transaction
    var account: Account
    var bucket: Bucket?
    var runningBalance: AccountRunningBalance
    
    private enum CodingKeys: String, CodingKey {
        case transaction, account = "Account", bucket = "Bucket", runningBalance
    }
}
