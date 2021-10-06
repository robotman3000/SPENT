//
//  TransactionRowContextMenu.swift
//  macOS
//
//  Created by Eric Nims on 8/24/21.
//

import SwiftUI
import SwiftUIKit
import UniformTypeIdentifiers

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
                            context.present(FormKeys.transfer(context: context, transaction: t.transaction, contextBucket: contextBucket, onSubmit: {data in
                                store.updateTransaction(&data, onComplete: { context.dismiss(); onFormDismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                            }))
                        }
                    } else if t.transaction.type == .Split_Head {
                        Button("Edit Split"){
                            context.present(FormKeys.splitTransaction(context: context, splitMembers: t.splitMembers, contextBucket: contextBucket, onSubmit: { data in
                                store.updateTransactions(&data, onComplete: { context.dismiss(); onFormDismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                            }))
                        }
                    } else {
                        Button("Edit Transaction") {
                            context.present(FormKeys.transaction(context: context, transaction: t.transaction, contextBucket: contextBucket, onSubmit: {data in
                                store.updateTransaction(&data, onComplete: { context.dismiss(); onFormDismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                            }))
                        }
                    }

                    Button("Add Document") {
                                //[UTType.plainText]
                        openFile(allowedTypes: [.data], onConfirm: { url in
                            if url.startAccessingSecurityScopedResource() {
                                do {
                                    defer { url.stopAccessingSecurityScopedResource() }
                                    // Generate the file hash and read the file data
                                    let data = try Data(contentsOf: url)
                                    let hash256 = data.sha256()
                                    
                                    // Create Attachment record
                                    var attachment = Attachment(filename: url.lastPathComponent, sha256: hash256)
                                    
                                    // Attempt to store the attachment to the DB
                                    // if this fails cleanup is easy
                                    store.updateAttachmentRecord(&attachment, onComplete: {}, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                                    
                                    // Copy the file to the db bundle
                                    //var attachmentPath: URL = store.getAttachmentPath(hash256)
                                    try store.storeAttachment(sourceURL: url, hash256: hash256)
                                    
                                    // Register the attachment with the transaction
                                    store.addTransactionAttachment(transaction: t.transaction, attachment: attachment)
                                } catch {
                                    //TODO: Handle failure conditions
                                    //throw Error.failedToLoadData
                                }
                            } else {
                                aContext.present(AlertKeys.message(message: "Failed to open file!"))
                            }
                        }, onCancel: { print("Document add cancled ") })
                    }
                    
                    Button("View Documents") {
                        aContext.present(AlertKeys.notImplemented)
                    }
                }
            }

            Button("Set Tags") {
                context.present(
                    FormKeys.transactionTags(
                        context: context,
                        transaction: transactions.first!.transaction,
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
                context.present(FormKeys.transaction(context: context, transaction: nil, contextBucket: contextBucket, onSubmit: {data in
                    store.updateTransaction(&data, onComplete: { context.dismiss(); onFormDismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                }))
            }

            Button("Add Transfer"){
                context.present(FormKeys.transfer(context: context, transaction: nil, contextBucket: contextBucket, onSubmit: {data in
                    store.updateTransaction(&data, onComplete: { context.dismiss(); onFormDismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                }))
            }

            Button("Add Split"){
                context.present(FormKeys.splitTransaction(context: context, splitMembers: [], contextBucket: contextBucket, onSubmit: { data in
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
