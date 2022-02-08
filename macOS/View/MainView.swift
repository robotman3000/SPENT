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
    @EnvironmentObject var databaseManager: DatabaseManager
    @Query(AllAccounts(), in: \.dbQueue) var accounts: [Account]
    @State var selection: Account?
    
    var body: some View {
        NavigationView {
            VStack {
                Button("Import CSV File") {
                    DispatchQueue.main.async {
                        let agent = CSVAgent()
                        openFile(allowedTypes: agent.allowedTypes, onConfirm: { selectedFile in
                            do {
                                try agent.importFromURL(url: selectedFile, database: databaseManager.database)
                            } catch {
                                print(error)
                                alertContext.present(AlertKeys.message(message: "Import Failed. \(error.localizedDescription)"))
                            }
                            alertContext.present(AlertKeys.message(message: "Import finished without errors"))
                        }, onCancel: {})
                    }
                }
                Section(header: Text("Balance")){
                    if let selectedAccount = _selection.wrappedValue {
                        Text("Balance of \(selectedAccount.name)").height(100).tag(0)
                    } else {
                        Text("").height(100).tag(0)
                    }
                }.collapsible(false)
                List(selection: $selection) {
                    Section(header: Text("Accounts")){
                        ForEach(accounts) { account in
                            NavigationLink(destination: AccountTransactionsView(forAccount: account)){
                                AccountRow(forAccount: account)
                            }.contextMenu { AccountContextMenu(sheet: sheetContext, forAccount: account) }.tag(account)
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
            .frame(minWidth: 300, maxWidth: 400)
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
    let forAccount: Account
    
    var body: some View {
        Text(forAccount.name)
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
    let forTransaction: Transaction
    
    var body: some View {
        HStack {
            Text(forTransaction.status.getStringName())
            Text(forTransaction.amount.currencyFormat)
            Text(forTransaction.entryDate.transactionFormat)
            Text(forTransaction.postDate?.transactionFormat ?? "N/A")
            Text(forTransaction.payee)
            Text(forTransaction.memo)
            Text("\(forTransaction.bucketID ?? -1)")
            Text("\(forTransaction.accountID)")
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
    @Query<AccountTransactions> var transactions: [Transaction]
    @State var selection: Transaction?
    
    init(forAccount: Account){
        self._transactions = Query(AccountTransactions(account: forAccount, bucket: nil), in: \.dbQueue)
        self.account = forAccount
    }
    
    var body: some View {
        Text("\(selection?.id! ?? -1)")
        List (selection: $selection){
            ForEach(transactions){ transaction in
                TransactionRow(forTransaction: transaction)
                    .contextMenu { TransactionContextMenu(sheet: sheetContext, forTransaction: transaction) }.tag(transaction)
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
