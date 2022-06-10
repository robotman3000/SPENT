//
//  TransactionTagForm.swift
//  SPENT
//
//  Created by Eric Nims on 6/29/21.
//

import SwiftUI
import GRDB

struct TransactionTagForm: View {
    @StateObject var model: TransactionTagFormModel
    
    let onSubmit: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            List(model.choices, id: \.self, selection: $model.tags) { tag in
                Text("\(tag.name)")
            }
        }.frame(minWidth: 250, minHeight: 300)
        .formFooter(model, onSubmit: onSubmit, onCancel: onCancel)
    }
}

//struct TransactionTagForm_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionTagForm()
//    }
//}
