//
//  AccountContextMenu.swift
//  macOS
//
//  Created by Eric Nims on 8/24/21.
//

import SwiftUI
import SwiftUIKit

struct AccountContextMenu: View {
    @EnvironmentObject var databaseManager: DatabaseManager
    @ObservedObject var context: SheetContext
    @ObservedObject var aContext: AlertContext
    let forAccount: Account
    
    var body: some View {
        Button("New Account"){
            context.present(FormKeys.account(context: context, account: nil))
        }
        
        Button("Edit \(forAccount.name)"){
            context.present(FormKeys.account(context: context, account: forAccount))
        }
        
        Button("Delete \(forAccount.name)"){
            context.present(FormKeys.confirmDelete(context: context, message: "",
                onConfirm: {
                    databaseManager.action(.deleteAccount(forAccount),
                    onSuccess: { print("deleted account successfully") },
                    onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))} )
            }))
        }
        
        Divider()
        
        Button("Add Transaction"){
            context.present(FormKeys.transaction(context: context, transaction: nil))
        }
        
        Button("Add Transfer"){
            context.present(FormKeys.transfer(context: context, transfer: nil))
        }
        
//        Button("Add Split"){
//            context.present(FormKeys.splitTransaction(context: context, splitHead: nil))
//        }
        
//            Divider()
//
//            Button("\(model.bucket.isFavorite ? "Unfavorite" : "Mark as Favorite")"){
//                model.bucket.isFavorite = !model.bucket.isFavorite
//                do {
//                    try store.write { db in
//                        try store.saveBucket(db, &model.bucket)
//                    }
//                } catch {
//                    aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))
//                }
//            }
        
    }
}

//struct AccountContextMenu_Previews: PreviewProvider {
//    static var previews: some View {
//        AccountContextMenu()
//    }
//}
