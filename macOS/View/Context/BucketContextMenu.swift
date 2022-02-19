//
//  BucketContextMenu.swift
//  macOS
//
//  Created by Eric Nims on 2/19/22.
//

import SwiftUI
import SwiftUIKit

struct BucketContextMenu: View {
    @EnvironmentObject var databaseManager: DatabaseManager
    @ObservedObject var sheet: SheetContext
    @ObservedObject var alertContext: AlertContext
    let forBucket: Bucket
    
    var body: some View {
        Button("Edit \(forBucket.name)") {
            sheet.present(FormKeys.bucket(context: sheet, bucket: forBucket))
        }
        Button("Delete \(forBucket.name)") {
            sheet.present(FormKeys.confirmDelete(context: sheet, message: "",
                onConfirm: {
                    databaseManager.action(.deleteBucket(forBucket),
                    onSuccess: { print("deleted bucket successfully") },
                    onError: { error in alertContext.present(AlertKeys.databaseError(message: error.localizedDescription ))} )
            }))
        }
    }
}

//struct BucketContextMenu_Previews: PreviewProvider {
//    static var previews: some View {
//        BucketContextMenu()
//    }
//}
