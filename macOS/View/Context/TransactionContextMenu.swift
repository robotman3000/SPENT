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
    
    let contextBucket: Int64?
    var forTransactions: Set<Int64>? = nil
    let forTransaction: TransactionModel?
    
    let onFormDismiss: () -> Void
    
    var body: some View {
        
        // Create new
        _NewTransactionContextButtons(context: context, aContext: aContext, contextBucket: contextBucket, onFormDismiss: onFormDismiss)

        if let model = forTransaction {
            
            // Edit
            Section {
                if model.transaction.type == .Transfer {
                    Button("Edit Transfer") {
                        context.present(FormKeys.transfer(context: context, transaction: model.transaction, contextBucket: contextBucket))
                    }
                } else if model.transaction.type == .Split_Head {
                    Button("Edit Split"){
                        context.present(FormKeys.splitTransaction(context: context, splitHead: model.transaction, contextBucket: contextBucket))
                    }
                } else {
                    Button("Edit Transaction") {
                        context.present(FormKeys.transaction(context: context, transaction: model.transaction, contextBucket: contextBucket))
                    }
                }
            }
            
            // Metadata
            Section {
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
                                store.addTransactionAttachment(transaction: model.transaction, attachment: attachment)
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
                    context.present(FormKeys.documentList(context: context, transaction: model.transaction))
                }
                
                Button("Set Tags") {
                    context.present(FormKeys.transactionTags(context: context, transaction: model.transaction))
                }
            }
            
            // Transaction Status
            Section{
                Button("Close Selected"){
                    markSelectionAs(newStatus: .Reconciled, filter: [.Void], transactions: [model])
                    onFormDismiss()
                }
                Menu("Mark As"){
                    Button("Void"){
                        markSelectionAs(newStatus: .Void, transactions: [model])
                        onFormDismiss()
                    }
                    Button("Complete"){
                        markSelectionAs(newStatus: .Complete, transactions: [model])
                        onFormDismiss()
                    }
                    Button("Reconciled"){
                        markSelectionAs(newStatus: .Reconciled, transactions: [model])
                        onFormDismiss()
                    }
                }
            }
            
            // Delete
            Button("Delete Selected") {
                context.present(FormKeys.confirmDelete(context: context, message: "", onConfirm: {
                    do {
                        try store.deleteTransaction(model.transaction.id!)
                    } catch {
                        aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))
                    }
                }))
            }
         
            Section{
                Button("Debug Info") {
                    aContext.present(AlertKeys.message(message: forTransaction.debugDescription))
                }
            }
        }
        Button("Debug Selection") {
            if let selection = forTransactions {
                print(selection.debugDescription)
            } else {
                print("No large selection")
            }
        }
    }
    
    func markSelectionAs(newStatus: Transaction.StatusTypes, filter: [Transaction.StatusTypes] = [], transactions: [TransactionModel]){
        var transactionsUpdated: [Transaction] = []
        for t in transactions {
            if filter.isEmpty || !filter.contains(t.transaction.status) {
                var tr = t.transaction
                tr.status = newStatus
                transactionsUpdated.append(tr)
            }
        }
        do {
            try store.updateTransactions(&transactionsUpdated)
        } catch {
            print(error)
            aContext.present(AlertKeys.databaseError(message: error.localizedDescription))
        }
    }
}

struct _NewTransactionContextButtons: View {
    @ObservedObject var context: SheetContext
    @ObservedObject var aContext: AlertContext
    @EnvironmentObject var store: DatabaseStore

    let contextBucket: Int64?
    let onFormDismiss: () -> Void
    
    var body: some View{
        Section{
            Button("Add Transaction") {
                context.present(FormKeys.transaction(context: context, transaction: nil, contextBucket: contextBucket))
            }

            Button("Add Transfer"){
                context.present(FormKeys.transfer(context: context, transaction: nil, contextBucket: contextBucket))
            }

            Button("Add Split"){
                context.present(FormKeys.splitTransaction(context: context, splitHead: nil, contextBucket: contextBucket))
            }
        }
    }
}

//struct TransactionRowContextMenu_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionRowContextMenu()
//    }
//}
