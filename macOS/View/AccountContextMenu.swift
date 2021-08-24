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
            context.present(UIForms.account(context: context, account: nil, onSubmit: {data in
                store.updateBucket(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
            }))
        }
        
        if(contextAccount.ancestorID == nil){
            Button("Edit Account"){
                context.present(UIForms.account(context: context, account: contextAccount, onSubmit: {data in
                    store.updateBucket(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
                }))
            }
            
            Button("Delete Account"){
                context.present(UIForms.confirmDelete(context: context, message: "", onConfirm: {
                    store.deleteBucket(contextAccount.id!, onError: {error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription )) })
                }))
            }
            
            Divider()
            
            Button("Add Bucket"){
                context.present(UIForms.bucket(context: context, bucket: nil, parent: contextAccount, parentChoices: store.accounts, budgetChoices: store.schedules, onSubmit: {data in
                    store.updateBucket(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
                }))
            }
        } else {
            Button("Edit Bucket"){
                context.present(UIForms.bucket(context: context, bucket: contextAccount, parent: nil, parentChoices: store.accounts, budgetChoices: store.schedules, onSubmit: {data in
                    store.updateBucket(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
                }))
            }
            
            Button("Delete Bucket"){
                context.present(UIForms.confirmDelete(context: context, message: "", onConfirm: {
                    store.deleteBucket(contextAccount.id!, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
                }))
            }
        }
    
        Divider()
        
        Button("Add Transaction"){
            context.present(UIForms.transaction(context: context, transaction: nil, contextBucket: contextAccount, bucketChoices: store.buckets, onSubmit: {data in
                store.updateTransaction(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
            }))
        }
        
        Button("Add Transfer"){
            context.present(UIForms.transfer(context: context, transaction: nil, contextBucket: contextAccount, sourceChoices: store.buckets, destChoices: store.buckets, onSubmit: {data in
                store.updateTransaction(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
            }))
        }
        
        Button("Add Split"){
            context.present(UIForms.splitTransaction(context: context, splitMembers: [], contextBucket: contextAccount, sourceChoices: store.buckets, destChoices: store.buckets, onSubmit: splitSubmit))
        }
    }
    
    func splitSubmit(transactions: inout [Transaction]) {
        store.updateTransactions(&transactions, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
    }
}

//struct AccountContextMenu_Previews: PreviewProvider {
//    static var previews: some View {
//        AccountContextMenu()
//    }
//}
