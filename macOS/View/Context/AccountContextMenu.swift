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
    @State var model: BucketModel?
    @EnvironmentObject private var store: DatabaseStore
    
    var body: some View {
        Button("New Account"){
            context.present(FormKeys.account(context: context, account: nil, onSubmit: {data in
                store.updateBucket(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
            }))
        }
        
        if var model = model {
            if(model.bucket.ancestorID == nil){
                Button("Edit Account"){
                    context.present(FormKeys.account(context: context, account: model.bucket, onSubmit: {data in
                        store.updateBucket(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                    }))
                }
                
                Button("Delete Account"){
                    context.present(FormKeys.confirmDelete(context: context, message: "", onConfirm: {
                        store.deleteBucket(model.bucket.id!, onError: {error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription )) })
                    }))
                }
                
                Divider()
                
                Button("Add Bucket"){
                    context.present(FormKeys.bucket(context: context, bucket: nil, parent: model.bucket, onSubmit: {data in
                        store.updateBucket(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                    }))
                }
            } else {
                Button("Edit Bucket"){
                    context.present(FormKeys.bucket(context: context, bucket: model.bucket, parent: nil, onSubmit: {data in
                        store.updateBucket(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                    }))
                }
                
                Button("Delete Bucket"){
                    context.present(FormKeys.confirmDelete(context: context, message: "", onConfirm: {
                        store.deleteBucket(model.bucket.id!, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                    }))
                }
            }
        
            Divider()
            
            Button("Add Transaction"){
                context.present(FormKeys.transaction(context: context, transaction: nil, contextBucket: model.bucket, onSubmit: {data in
                    store.updateTransaction(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                }))
            }
            
            Button("Add Transfer"){
                context.present(FormKeys.transfer(context: context, transaction: nil, contextBucket: model.bucket, onSubmit: {data in
                    store.updateTransaction(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                }))
            }
            
            Button("Add Split"){
                context.present(FormKeys.splitTransaction(context: context, splitMembers: [], contextBucket: model.bucket, onSubmit: splitSubmit))
            }
            
            Divider()
            
            Button("\(model.bucket.isFavorite ? "Unfavorite" : "Mark as Favorite")"){
                model.bucket.isFavorite = !model.bucket.isFavorite
                store.updateBucket(&model.bucket, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
            }
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
