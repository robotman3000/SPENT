//
//  AccountTransactionsView.swift
//  macOS
//
//  Created by Eric Nims on 5/13/22.
//

import SwiftUI
import SwiftUIKit
import GRDBQuery

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
        let highlightRows = UserDefaults.standard.bool(forKey: PreferenceKeys.highlightRowsByStatus.rawValue)
        
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
                    
                    TransactionListRow(model: transactionInfo, showRunning: showRunningBalance, showEntryDate: showEntryDate, rowMode: rowMode, enableHighlight: highlightRows)
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

//struct AccountTransactionsView_Previews: PreviewProvider {
//    static var previews: some View {
//        AccountTransactionsView()
//    }
//}
