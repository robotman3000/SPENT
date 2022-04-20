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

struct AccountBucketsListView: View {
    @StateObject var sheetContext = SheetContext()
    @StateObject var alertContext = AlertContext()
    @Query<AccountBuckets> var buckets: [BucketInfo]
    let account: Account
    @State var selection: Bucket? = nil as Bucket?
    
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
            ForEachEnumerated(buckets.sorted(by: { a, b in a.bucket.category < b.bucket.category })){ bucketInfo in
                NavigationLink(destination: AccountTransactionsView(forAccount: account, withBucket: selection), tag: bucketInfo.bucket, selection: $selection){
                    BucketListRow(forBucket: bucketInfo)
                }.contextMenu { BucketContextMenu(sheet: sheetContext, alertContext: alertContext, forBucket: bucketInfo.bucket) }
            }
            
            if buckets.isEmpty {
                Text("No Buckets")
            }
        }.sheet(context: sheetContext)
        .alert(context: alertContext)
        .contextMenu {
            Button("New Bucket"){
                sheetContext.present(FormKeys.bucket(context: sheetContext, bucket: nil))
            }
        }
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
        VStack{
            // Bucket Toolbar
            AccountBucketToolbar(forAccount: account, withBucket: bucket)
            
            // Main transaction list
            
            //TODO: changing the value of showAllocations currently causes the entire transaction list to be recreated. Is there a more lightweight solution?
            TransactionsList(forAccount: account, forBucket: bucket, sheetContext: sheetContext, alertContext: alertContext, showAllocations: globalState.showAllocations, showCleared: globalState.showCleared, rowMode: globalState.transRowMode, orderBy: globalState.sorting, orderDirection: globalState.sortDirection)
            
        }.sheet(context: sheetContext)
        .alert(context: alertContext)
        .toolbar {
            ToolbarItem(placement: .automatic){
                Menu (content: {
                    Button("New Transaction"){
                        sheetContext.present(FormKeys.transaction(context: sheetContext, transaction: nil))
                    }
                    Button("New Transfer"){
                        sheetContext.present(FormKeys.transfer(context: sheetContext, transfer: nil))
                    }
                    Button("New Split"){
                        sheetContext.present(FormKeys.splitTransaction(context: sheetContext, split: nil))
                    }
                    Divider()
                    Menu(content: {
                        TemplateButtonList(sheetContext: sheetContext)
                    }, label: { Text("Templates") })
                    
                }, label: { Image(systemName: "plus") })
            }
        }
    }
    
    private struct TemplateButtonList: View {
        @Query(AllTemplates(), in: \.dbQueue) var templates: [TransactionTemplate]
        @StateObject var sheetContext = SheetContext()
        
        var body: some View {
            ForEach(templates) { template in
                Button(template.getName()){
                    sheetContext.present(FormKeys.transaction(context: sheetContext, transaction: template.render()))
                }
            }
            
            if templates.isEmpty {
                Text("No Templates").disabled(true)
            }
        }
    }
    
    private struct TransactionsList: View {
        @ObservedObject var sheetContext: SheetContext
        @ObservedObject var alertContext: AlertContext
        @Query<AccountTransactions> var transactions: [TransactionInfo]
        @State var selection = Set<Transaction>()
        let showRunningBalance: Bool
        let showEntryDate: Bool
        let rowMode: TransactionRowMode
        
        init(forAccount: Account, forBucket: Bucket?, sheetContext: SheetContext, alertContext: AlertContext, showAllocations: Bool = true, showCleared: Bool = true, rowMode: TransactionRowMode, orderBy: Transaction.Ordering, orderDirection: Transaction.OrderDirection){
            selection = Set<Transaction>()
            
            self._transactions = Query(AccountTransactions(account: forAccount, bucket: forBucket, excludeAllocations: !showAllocations, excludeCleared: !showCleared, direction: orderDirection, ordering: orderBy), in: \.dbQueue)
            self.sheetContext = sheetContext
            self.alertContext = alertContext
            self.showRunningBalance = forBucket == nil && orderBy == .byPostDate
            self.showEntryDate = orderBy == .byEntryDate
            self.rowMode = rowMode
        }
        
        var body: some View {
            List (selection: $selection){
                ForEachEnumerated(transactions){ transactionInfo in
                    TransactionListRow(model: transactionInfo, showRunning: showRunningBalance, showEntryDate: showEntryDate, rowMode: rowMode)
                        .contextMenu {
                            TransactionContextMenu(context: sheetContext, aContext: alertContext, model: transactionInfo, selection: $selection)
                        }.tag(transactionInfo.transaction)
                }
            }.contextMenu {
                _NewTransactionContextButtons(context: sheetContext, aContext: alertContext)
            }
            TransactionInfoBar(selection: selection)
        }
    }
    
    private struct TransactionInfoBar: View {
        let selection: Set<Transaction>
        var selectionTotal: Int {
            get {
                var sum = 0
                for item in selection {
                    sum += item.amount
                }
                return sum
            }
        }
        
        var body: some View {
            HStack{
                // Selection Count
                Text("\(selection.count) selected")
                
                // Selection Amount Sum
                Text("Sum: \(selectionTotal.currencyFormat)")
            }.padding()
        }
    }
}

struct AccountBucketToolbar: View {
    @EnvironmentObject var globalState: GlobalState
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
            VStack(alignment: .leading) {
                Toggle("Show Allocations", isOn: $globalState.showAllocations)
                Toggle("Show Cleared", isOn: $globalState.showCleared)
            }
            VStack {
                EnumPicker(label: "Sort By", selection: $globalState.sorting, enumCases: [.byPostDate, .byEntryDate, .byAmount, .byBucket, .byMemo, .byPayee, .byStatus])
                EnumPicker(label: "", selection: $globalState.sortDirection, enumCases: Transaction.OrderDirection.allCases).pickerStyle(SegmentedPickerStyle())
            }.frame(maxWidth: 200)
            VStack {
                EnumPicker(label: "", selection: $globalState.transRowMode, enumCases: TransactionRowMode.allCases).pickerStyle(SegmentedPickerStyle())
            }.frame(maxWidth: 200)
            //TextField("", text: $stringFilter)
            Spacer()
            if let bucket = bucket {
                BucketBalanceView(forAccount: account, forBucket: bucket)
            }
        }.padding()
    }
}

enum TransactionRowMode: String, Identifiable, CaseIterable, Stringable {
    case compact
    case full
    
    var id: String { self.rawValue }
    
    func getStringName() -> String {
        switch self {
        case .compact: return "Compact"
        case .full: return "Full"
        }
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
            Text("Available: \(balance?.available.currencyFormat ?? "NIL")").foregroundColor(balance?.available ?? 0 < 0 ? .red : .black)
            Text("Posted: \(balance?.posted.currencyFormat ?? "NIL")").foregroundColor(balance?.posted ?? 0 < 0 ? .red : .black)
            
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
            ORDER BY Accounts.Name ASC
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
    let runningBalance: Int?
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
    var split: SplitTransaction?
    var runningBalance: AccountRunningBalance?
    var tags: [Tag]
    
    var type: Transaction.TransType {
        if split != nil {
            return .Split
        }
        
        if transfer != nil {
            return .Transfer
        }
        
        if transaction.amount < 0 {
            return .Withdrawal
        }
        
        return .Deposit
    }
    //var transType: TransactionType
    
    private enum CodingKeys: String, CodingKey {
        case transaction, account = "Account", bucket = "Bucket", runningBalance, transfer, split, tags = "Tags"
    }
}
