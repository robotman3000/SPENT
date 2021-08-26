//
//  TransactionRowContextMenu.swift
//  macOS
//
//  Created by Eric Nims on 8/24/21.
//

import SwiftUI
import SwiftUIKit

struct TransactionContextMenu: View {
    @ObservedObject var context: SheetContext
    @ObservedObject var aContext: AlertContext
    @EnvironmentObject var store: DatabaseStore
    
    let contextBucket: Bucket
    let transactions: Set<TransactionData>
    
    let onFormDismiss: () -> Void
    
    var body: some View {
        
        _NewTransactionContextButtons(context: context, aContext: aContext, contextBucket: contextBucket, onFormDismiss: onFormDismiss)
        
        Section {
            if let t = transactions.first { // No support for batch editing... yet
                if transactions.count == 1 {
                    if t.transaction.type == .Transfer {
                        Button("Edit Transfer") {
                            context.present(FormKeys.transfer(context: context, transaction: t.transaction, contextBucket: contextBucket, sourceChoices: store.buckets, destChoices: store.buckets, onSubmit: {data in
                                store.updateTransaction(&data, onComplete: { context.dismiss(); onFormDismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                            }))
                        }
                    } else if t.transaction.type == .Split {
                        Button("Edit Split"){
                            context.present(FormKeys.splitTransaction(context: context, splitMembers: t.splitMembers, contextBucket: contextBucket, sourceChoices: store.buckets, destChoices: store.buckets, onSubmit: { data in
                                store.updateTransactions(&data, onComplete: { context.dismiss(); onFormDismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                            }))
                        }
                    } else {
                        Button("Edit Transaction") {
                            context.present(FormKeys.transaction(context: context, transaction: t.transaction, contextBucket: contextBucket, bucketChoices: store.buckets, onSubmit: {data in
                                store.updateTransaction(&data, onComplete: { context.dismiss(); onFormDismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                            }))
                        }
                    }

                    Button("Add Document") {
                        aContext.present(AlertKeys.notImplemented)
                    }
                }
            }

            Button("Set Tags") {
                context.present(
                    FormKeys.transactionTags(
                        context: context,
                        transaction: transactions.first!.transaction,
                        tagChoices: store.tags,
                        onSubmit: {tags, transaction in
                            print(tags)
                            store.setTransactionsTags(transactions: transactions.map({ t in t.transaction }), tags: tags, onComplete: { context.dismiss(); onFormDismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                        }
                    )
                )
            }
        }
        

        Section{
            Button("Close Selected"){
                markSelectionAs(newStatus: .Reconciled, filter: [.Void])
                onFormDismiss()
            }
            Menu("Mark As"){
                Button("Void"){
                    markSelectionAs(newStatus: .Void)
                    onFormDismiss()
                }
                Button("Complete"){
                    markSelectionAs(newStatus: .Complete)
                    onFormDismiss()
                }
                Button("Reconciled"){
                    markSelectionAs(newStatus: .Reconciled)
                    onFormDismiss()
                }
            }
        }

        Button("Delete Selected") {
            context.present(FormKeys.confirmDelete(context: context, message: "", onConfirm: {
                store.deleteTransactions(transactions.map({t in t.transaction.id!}), onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
            }))
        }

        Section{
            Button("Debug Info") {
                aContext.present(AlertKeys.message(message: transactions.debugDescription))
            }
        }
    }
    
    func markSelectionAs(newStatus: Transaction.StatusTypes, filter: [Transaction.StatusTypes] = []){
        var transactionsUpdated: [Transaction] = []
        for t in transactions {
            if filter.isEmpty || !filter.contains(t.transaction.status) {
                var tr = t.transaction
                tr.status = newStatus
                transactionsUpdated.append(tr)
            }
        }
        store.updateTransactions(&transactionsUpdated, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
    }
}

struct _NewTransactionContextButtons: View {
    @ObservedObject var context: SheetContext
    @ObservedObject var aContext: AlertContext
    @EnvironmentObject var store: DatabaseStore
    let contextBucket: Bucket
    let onFormDismiss: () -> Void
    
    var body: some View{
        Section{
            Button("Add Transaction") {
                context.present(FormKeys.transaction(context: context, transaction: nil, contextBucket: contextBucket, bucketChoices: store.buckets, onSubmit: {data in
                    store.updateTransaction(&data, onComplete: { context.dismiss(); onFormDismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                }))
            }

            Button("Add Transfer"){
                context.present(FormKeys.transfer(context: context, transaction: nil, contextBucket: contextBucket, sourceChoices: store.buckets, destChoices: store.buckets, onSubmit: {data in
                    store.updateTransaction(&data, onComplete: { context.dismiss(); onFormDismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                }))
            }

            Button("Add Split"){
                context.present(FormKeys.splitTransaction(context: context, splitMembers: [], contextBucket: contextBucket, sourceChoices: store.buckets, destChoices: store.buckets, onSubmit: { data in
                    store.updateTransactions(&data, onComplete: { context.dismiss(); onFormDismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                }))
            }
        }
    }
}

//struct TransactionRowContextMenu_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionRowContextMenu()
//    }
//}
