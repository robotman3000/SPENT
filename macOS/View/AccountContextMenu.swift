//
//  AccountContextMenu.swift
//  macOS
//
//  Created by Eric Nims on 8/24/21.
//

import SwiftUI
import SwiftUIKit

struct AccountContextMenu: View {
    @ObservedObject var context: SheetContext
    @ObservedObject var aContext: AlertContext
    @State var contextAccount: Bucket
    @EnvironmentObject private var store: DatabaseStore
    
    var body: some View {
        Button("New Account"){
            context.present(FormKeys.account(context: context, account: nil, onSubmit: {data in
                store.updateBucket(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
            }))
        }
        
        if(contextAccount.ancestorID == nil){
            Button("Edit Account"){
                context.present(FormKeys.account(context: context, account: contextAccount, onSubmit: {data in
                    store.updateBucket(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                }))
            }
            
            Button("Delete Account"){
                context.present(FormKeys.confirmDelete(context: context, message: "", onConfirm: {
                    store.deleteBucket(contextAccount.id!, onError: {error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription )) })
                }))
            }
            
            Divider()
            
            Button("Add Bucket"){
                context.present(FormKeys.bucket(context: context, bucket: nil, parent: contextAccount, onSubmit: {data in
                    store.updateBucket(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                }))
            }
        } else {
            Button("Edit Bucket"){
                context.present(FormKeys.bucket(context: context, bucket: contextAccount, parent: nil, onSubmit: {data in
                    store.updateBucket(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                }))
            }
            
            Button("Delete Bucket"){
                context.present(FormKeys.confirmDelete(context: context, message: "", onConfirm: {
                    store.deleteBucket(contextAccount.id!, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                }))
            }
        }
    
        Divider()
        
        Button("Add Transaction"){
            context.present(FormKeys.transaction(context: context, transaction: nil, contextBucket: contextAccount, onSubmit: {data in
                store.updateTransaction(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
            }))
        }
        
        Button("Add Transfer"){
            context.present(FormKeys.transfer(context: context, transaction: nil, contextBucket: contextAccount, onSubmit: {data in
                store.updateTransaction(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
            }))
        }
        
        Button("Add Split"){
            context.present(FormKeys.splitTransaction(context: context, splitMembers: [], contextBucket: contextAccount, onSubmit: splitSubmit))
        }
    }
    
    func splitSubmit(transactions: inout [Transaction]) {
        store.updateTransactions(&transactions, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
    }
}

//struct AccountContextMenu_Previews: PreviewProvider {
//    static var previews: some View {
//        AccountContextMenu()
//    }
//}
