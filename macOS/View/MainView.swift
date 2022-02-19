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
            }
            .frame(minWidth: 300)
            .navigationTitle("Accounts")
            
            EmptyView()
            EmptyView()
            
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

struct AccountBucketsListView: View {
    @StateObject var sheetContext = SheetContext()
    @StateObject var alertContext = AlertContext()
    @Query<AccountBuckets> var buckets: [BucketInfo]
    let account: Account
    @State var selection: Bucket?
    
    init(forAccount: Account){
        self._buckets = Query(AccountBuckets(forAccount: forAccount), in: \.dbQueue)
        self.account = forAccount
    }
    
    var body: some View {
        List {
            NavigationLink(destination: AccountTransactionsView(forAccount: account, withBucket: nil)){
                Text("All Transactions")
            }
            Divider()
            ForEachEnumerated(buckets){ bucketInfo in
                NavigationLink(destination: AccountTransactionsView(forAccount: account, withBucket: selection), tag: bucketInfo.bucket, selection: $selection){
                    BucketRow(forBucket: bucketInfo)
                }.contextMenu { BucketContextMenu(sheet: sheetContext, forBucket: bucketInfo.bucket) }
            }
            
            if buckets.isEmpty {
                Text("No Buckets")
            }
        }.sheet(context: sheetContext)
        .alert(context: alertContext)
    }
}

struct BucketRow: View {
    let forBucket: BucketInfo
    
    var body: some View {
        HStack {
            Text(forBucket.bucket.name)
            Spacer()
            Text(forBucket.balance.available.currencyFormat)
        }
    }
}

struct TransactionRow: View {
    let forTransaction: TransactionInfo
    
    var body: some View {
        HStack {
            Text(forTransaction.transaction.status.getStringName())
            Text(forTransaction.transaction.amount.currencyFormat)
            //Text(forTransaction.transType.type)
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

struct BucketContextMenu: View {
    @EnvironmentObject var databaseManager: DatabaseManager
    @ObservedObject var sheet: SheetContext
    let forBucket: Bucket
    
    var body: some View {
        Button("Edit bucket") {
            sheet.present(FormKeys.bucket(context: sheet, bucket: forBucket))
        }
        Button("Delete \(forBucket.name)") {
            databaseManager.action(.deleteBucket(forBucket), onSuccess: {
                print("deleted bucket successfully")
            })
        }
    }
}

struct TransactionContextMenu: View {
    @EnvironmentObject var databaseManager: DatabaseManager
    @ObservedObject var sheet: SheetContext
    let forTransaction: TransactionInfo
    
    var body: some View {
        if let transfer = forTransaction.transfer {
            Button("Edit transfer") {
                sheet.present(FormKeys.transfer(context: sheet, transfer: transfer))
            }
        }
            
        Button("Edit transaction") {
            sheet.present(FormKeys.transaction(context: sheet, transaction: forTransaction.transaction))
        }
        
        Button("Delete transaction") {
            databaseManager.action(.deleteTransaction(forTransaction.transaction), onSuccess: {
                print("deleted transaction successfully")
            })
        }
    }
}

struct AccountTransactionsView: View {
    @StateObject var sheetContext = SheetContext()
    let account: Account
    let bucket: Bucket?
    
    init(forAccount: Account, withBucket: Bucket?){
        self.account = forAccount
        self.bucket = withBucket
    }
    
    var body: some View {
        VStack{
            // Bucket Toolbar
            AccountBucketToolbar(forAccount: account, withBucket: bucket)
            
            // Main transaction list
            TransactionsList(forAccount: account, forBucket: bucket, sheetContext: sheetContext)
            
        }.sheet(context: sheetContext)
    }
    
    private struct TransactionsList: View {
        @ObservedObject var sheetContext: SheetContext
        @Query<AccountTransactions> var transactions: [TransactionInfo]
        @State var selection: Transaction?
        
        init(forAccount: Account, forBucket: Bucket?, sheetContext: SheetContext){
            self._transactions = Query(AccountTransactions(account: forAccount, bucket: forBucket), in: \.dbQueue)
            self.sheetContext = sheetContext
        }
        
        var body: some View {
            List (selection: $selection){
                ForEachEnumerated(transactions){ transactionInfo in
                    TransactionRow(forTransaction: transactionInfo)
                        .contextMenu { TransactionContextMenu(sheet: sheetContext, forTransaction: transactionInfo) }.tag(transactionInfo.transaction)
                }
            }
        }
    }
}

struct AccountBucketToolbar: View {
    let account: Account
    let bucket: Bucket?
    @Query<AccountBuckets> var buckets: [BucketInfo]
    @State private var showingManager: Bool = false
    
    init(forAccount: Account, withBucket: Bucket? = nil){
        self._buckets = Query(AccountBuckets(forAccount: forAccount), in: \.dbQueue)
        self.account = forAccount
        self.bucket = withBucket
    }
    
    var body: some View {
        HStack {
            if let bucket = bucket {
                BucketBalanceView(forAccount: account, forBucket: bucket)
            }
        }.padding()
    }
}

struct BucketBalanceView: View {
    @Query<BucketBalanceQuery> var balance: BucketBalance?
    
    init(forAccount: Account, forBucket: Bucket){
        self._balance = Query(BucketBalanceQuery(forAccount: forAccount, forBucket: forBucket), in: \.dbQueue)
    }
    
    var body: some View {
        VStack {
            // Bucket posted and available balance
            Text("Available: \(balance?.available.currencyFormat ?? "NIL")")
            Text("Posted: \(balance?.posted.currencyFormat ?? "NIL")")
            
            //count open(pending, submitted, complete), planned(uninit)
            
        }
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

struct BucketBalance: Decodable, FetchableRecord, TableRecord {
    let bucketId: Int64
    let accountId: Int64
    let posted: Int
    let available: Int
    
    static let account = hasOne(Account.self, using: ForeignKey(["id"], to: ["AccountID"]))
    static let bucket = hasOne(Bucket.self, using: ForeignKey(["id"], to: ["BucketID"]))
}

extension DerivableRequest where RowDecoder == BucketBalance {
    func filter(account: Account) -> Self {
        filter(Column("AccountID") == account.id)
    }
    
    func filter(bucket: Bucket) -> Self {
        filter(Column("BucketID") == bucket.id)
    }
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

struct BucketInfo: Decodable, FetchableRecord {
    var balance: BucketBalance
    var account: Account
    var bucket: Bucket
    
    private enum CodingKeys: String, CodingKey {
        case balance, account = "Account", bucket = "Bucket"
    }
}

//extension BucketInfo {
//    /// The request for all bucket infos except the buckets that "don't exist" I.E. The buckets without any transactions
//    static func all() -> AdaptedFetchRequest<SQLRequest<BucketInfo>> {
//        let request: SQLRequest<BucketInfo> = """
//            SELECT
//                \(columnsOf: Bucket.self),
//                \(columnsOf: BucketBalance.self),
//                \(columnsOf: Account.self)
//            FROM BucketBalance
//            JOIN Buckets ON ("Buckets".id == BucketID) JOIN Accounts ON ("Accounts".id == AccountID)
//        """
//        return request.adapted { db in
//            let adapters = try splittingRowAdapters(columnCounts: [
//                Bucket.numberOfSelectedColumns(db),
//                BucketBalance.numberOfSelectedColumns(db),
//                Account.numberOfSelectedColumns(db)])
//            return ScopeAdapter([
//                CodingKeys.bucket.stringValue: adapters[0],
//                CodingKeys.balance.stringValue: adapters[1],
//                CodingKeys.account.stringValue: adapters[2]])
//        }
//    }
//
//    /// Fetches all account infos
//    static func fetchAll(_ db: Database) throws -> [BucketInfo] {
//        try all().fetchAll(db)
//    }
//}

struct AccountRunningBalance: Decodable, FetchableRecord, TableRecord {
    let runningBalance: Int
    let accountID: Int64
    let transactionID: Int64
}

struct TransactionType: Decodable, FetchableRecord, TableRecord {
    let id: Int64
    let type: String
}

struct TransactionInfo: Decodable, FetchableRecord {
    var transaction: Transaction
    var account: Account
    var bucket: Bucket?
    var transfer: Transfer?
    var runningBalance: AccountRunningBalance
    //var transType: TransactionType
    
    private enum CodingKeys: String, CodingKey {
        case transaction, account = "Account", bucket = "Bucket", runningBalance, transfer
    }
}
