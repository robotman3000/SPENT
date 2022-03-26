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
    @EnvironmentObject var databaseManager: DatabaseManager
    @ObservedObject var context: SheetContext
    @ObservedObject var aContext: AlertContext
    let model: TransactionInfo
    @Binding var selection: Set<Transaction>
    
    var body: some View {
        
        // Create new
        _NewTransactionContextButtons(context: context, aContext: aContext)

        // Edit
        Section {
            if let transfer = model.transfer {
                Button("Edit Transfer") {
                    context.present(FormKeys.transfer(context: context, transfer: transfer))
                }
            }

            if let split = model.split {
                Button("Edit Split"){
                    context.present(FormKeys.splitTransaction(context: context, split: split))
                }
            }
            
            Button(model.type == .Transfer || model.type == .Split ? "Edit As Transaction" : "Edit Transaction") {
                context.present(FormKeys.transaction(context: context, transaction: model.transaction))
            }
            
        }

        // Metadata
        Section {
//                Button("Add Document") {
//                            //[UTType.plainText]
//                    openFile(allowedTypes: [.data], onConfirm: { url in
//                        if url.startAccessingSecurityScopedResource() {
//                            do {
//                                defer { url.stopAccessingSecurityScopedResource() }
//                                // Generate the file hash and read the file data
//                                let data = try Data(contentsOf: url)
//                                let hash256 = data.sha256()
//
//                                // Create Attachment record
//                                var attachment = Attachment(filename: url.lastPathComponent, sha256: hash256)
//
//                                // Attempt to store the attachment to the DB
//                                // if this fails cleanup is easy
//                                store.updateAttachmentRecord(&attachment, onComplete: {}, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
//
//                                // Copy the file to the db bundle
//                                //var attachmentPath: URL = store.getAttachmentPath(hash256)
//                                try store.storeAttachment(sourceURL: url, hash256: hash256)
//
//                                // Register the attachment with the transaction
//                                store.addTransactionAttachment(transaction: model.transaction, attachment: attachment)
//                            } catch {
//                                //TODO: Handle failure conditions
//                                //throw Error.failedToLoadData
//                            }
//                        } else {
//                            aContext.present(AlertKeys.message(message: "Failed to open file!"))
//                        }
//                    }, onCancel: { print("Document add cancled ") })
//                }
//
//                Button("View Documents") {
//                    context.present(FormKeys.documentList(context: context, transaction: model.transaction))
//                }
            
            Button("Set Tags") {
                context.present(FormKeys.transactionTags(context: context, transaction: model.transaction))
            }
            
            Button("Clear Post Date") {
                databaseManager.action(.setTransactionPostDate(nil, model.transaction))
            }
        }
        
        // Transaction Status
        Section{
            let array = selection.isEmpty ? [model.transaction] : Array(selection)
            Button("Close Selected"){
                databaseManager.action(.setTransactionsStatus(.Reconciled, Array(array).filter({ item in
                    item.status != .Void
                })))
                selection.removeAll()
            }
            Menu("Mark As"){
                Button("Void"){
                    databaseManager.action(.setTransactionsStatus(.Void, Array(array)))
                    selection.removeAll()
                }
                Button("Complete"){
                    databaseManager.action(.setTransactionsStatus(.Complete, Array(array)))
                    selection.removeAll()
                }
                Button("Reconciled"){
                    databaseManager.action(.setTransactionsStatus(.Reconciled, Array(array)))
                    selection.removeAll()
                }
            }
        }
        
        // Delete
        //TODO: Support multiselect
        Button("Delete Transaction") {
            context.present(FormKeys.confirmDelete(context: context, message: "",
                onConfirm: {
                    let deleteAction = model.split != nil && model.split!.transactionID == model.split!.splitHeadTransactionID ?
                        DatabaseActions.deleteSplitTransaction(model.split!) :
                        DatabaseActions.deleteTransaction(model.transaction)
                    databaseManager.action(deleteAction,
                    onSuccess: { print("deleted transaction successfully") },
                    onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))} )
            }))
        }

//        Section{
//            Button("Debug Info") {
//                aContext.present(AlertKeys.message(message: model.debugDescription))
//            }
//        }
    }
}

struct _NewTransactionContextButtons: View {
    @ObservedObject var context: SheetContext
    @ObservedObject var aContext: AlertContext
    
    var body: some View{
        Section{
            Menu("New") {
                Button("Transaction") {
                    context.present(FormKeys.transaction(context: context, transaction: nil))
                }

                Button("Transfer"){
                    context.present(FormKeys.transfer(context: context, transfer: nil))
                }

                Button("Split"){
                    context.present(FormKeys.splitTransaction(context: context, split: nil))
                }
            }
            
        }
    }
}

//struct TransactionRowContextMenu_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionRowContextMenu()
//    }
//}
