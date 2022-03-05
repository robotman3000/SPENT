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

class TransactionTagFormModel: FormModel {
    fileprivate var transaction: Transaction

    @Published var tags: Set<Tag> = Set<Tag>()
    @Published var choices: [Tag] = []
    
    init(transaction: Transaction){
        self.transaction = transaction
    }
    
    func loadState(withDatabase: Database) throws {
        let tags = try transaction.tags.fetchAll(withDatabase)
        self.tags = Set(tags)
        choices = try Tag.all().fetchAll(withDatabase)
    }
    
    func validate() throws {}
    
    func submit(withDatabase: Database) throws {
        try DatabaseActions.setTransactionTags(transaction, Array(tags)).execute(db: withDatabase)
    }
}

//struct TransactionTagForm_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionTagForm()
//    }
//}
