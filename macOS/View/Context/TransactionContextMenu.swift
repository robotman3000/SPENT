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
            
            Button("Edit Transaction") {
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
            
//            Button("Set Tags") {
//                context.present(FormKeys.transactionTags(context: context, transaction: model.transaction))
//            }
        }
        
        // Transaction Status
        Section{
            Button("Close Selected"){
                databaseManager.action(.setTransactionsStatus(.Reconciled, Array(selection).filter({ item in
                    item.status != .Void
                })))
                selection.removeAll()
            }
            Menu("Mark As"){
                Button("Void"){
                    databaseManager.action(.setTransactionsStatus(.Void, Array(selection)))
                    selection.removeAll()
                }
                Button("Complete"){
                    databaseManager.action(.setTransactionsStatus(.Complete, Array(selection)))
                    selection.removeAll()
                }
                Button("Reconciled"){
                    databaseManager.action(.setTransactionsStatus(.Reconciled, Array(selection)))
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
            Button("Add Transaction") {
                context.present(FormKeys.transaction(context: context, transaction: nil))
            }

            Button("Add Transfer"){
                context.present(FormKeys.transfer(context: context, transfer: nil))
            }

//            Button("Add Split"){
//                context.present(FormKeys.splitTransaction(context: context, splitHead: nil))
//            }
        }
    }
}

//struct TransactionRowContextMenu_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionRowContextMenu()
//    }
//}

/*
 
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
 */
