//
//  TransactionTagFormModel.swift
//  SPENT
//
//  Created by Eric Nims on 6/8/22.
//

import GRDB
import SwiftUI

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
        try SetTransactionTagsAction(transaction: transaction, tags: Array(tags)).execute(db: withDatabase)
    }
}
