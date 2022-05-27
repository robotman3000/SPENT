//
//  DatabaseAction.swift
//  macOS
//
//  Created by Eric Nims on 2/1/22.
//

import Foundation
import GRDB

protocol DatabaseAction {
    func execute(db: Database) throws
}

protocol UndoableDatabaseAction {
    func executeUndoable(db: Database, undoManager: UndoManager?) throws
    func registerUndoWithMangager(undoManager: UndoManager?)
}

class BaseUndoableDatabaseAction: BaseDatabaseAction, UndoableDatabaseAction {
    func executeUndoable(db: Database, undoManager: UndoManager?) throws {
        self.registerUndoWithMangager(undoManager: undoManager)
        try self.execute(db: db)
    }
    func registerUndoWithMangager(undoManager: UndoManager?) {}
}

class BaseDatabaseAction: DatabaseAction {
    func execute(db: Database) throws {}
}

class DuplicateTransactionAction: BaseUndoableDatabaseAction {
    let transaction: Transaction
    
    init(transaction: Transaction){
        self.transaction = transaction
    }
    
    override func execute(db: Database) throws {
        var trans = transaction // Clone the struct (Structs are value types not reference types)
        trans.id = nil // Clear the id so it will get a new one
        try trans.save(db)
    }
    
    override func registerUndoWithMangager(undoManager: UndoManager?) {
        undoManager?.registerUndo(withTarget: self) {
            $0.undo()
        }
        undoManager?.setActionName("Duplicate Transaction")
    }
    
    private func undo(){
        print("Undo action worked!")
    }
}

class DeleteAccountAction: BaseDatabaseAction {
    let account: Account
    
    init(account: Account){
        self.account = account
    }
    
    override func execute(db: Database) throws {
        try account.delete(db)
    }
}

class DeleteBucketAction: BaseDatabaseAction {
    let bucket: Bucket
    
    init(bucket: Bucket){
        self.bucket = bucket
    }
    
    override func execute(db: Database) throws {
        try bucket.delete(db)
    }
}

class DeleteTransactionAction: BaseDatabaseAction {
    let transaction: Transaction
    
    init(transaction: Transaction){
        self.transaction = transaction
    }
    
    override func execute(db: Database) throws {
        //TODO: What if the transaction is actually a transfer?
        try transaction.delete(db)
    }
}

class DeleteTransferAction: BaseDatabaseAction {
    let transfer: Transfer
    
    init(transfer: Transfer){
        self.transfer = transfer
    }
    
    //TODO: Impl execute
}

class DeleteSplitTransactionAction: BaseDatabaseAction {
    let split: SplitTransaction
    
    init(split: SplitTransaction){
        self.split = split
    }
    
    override func execute(db: Database) throws {
        // Fetch all the split transaction records with the same uuid
        let splits = try SplitTransaction.filter(SplitTransaction.Columns.splitUUID == split.splitUUID.uuidString).fetchAll(db)
        
        // Get the list of linked transactions
        let transactionIDs = splits.map { $0.transactionID }
        
        // Delete split records first to satisfy foreign key requirements
        try SplitTransaction.filter(ids: splits.map{ $0.id! }).deleteAll(db)
        
        // Delete the transactions
        try Transaction.filter(ids: transactionIDs).deleteAll(db)
    }
}

class DeleteTagAction: BaseDatabaseAction {
    let tag: Tag
    
    init(tag: Tag){
        self.tag = tag
    }
    
    override func execute(db: Database) throws {
        try tag.delete(db)
    }
    
}

class DeleteTransactionTemplateAction: BaseDatabaseAction {
    let template: TransactionTemplate
    
    init(template: TransactionTemplate){
        self.template = template
    }
    
    override func execute(db: Database) throws {
        try template.delete(db)
    }
}

class SetTransactionsStatusAction: BaseDatabaseAction {
    let forTransactions: [Transaction]
    let toStatus: Transaction.StatusTypes
    
    init(status: Transaction.StatusTypes, transactions: [Transaction]){
        self.forTransactions = transactions
        self.toStatus = status
    }
    
    override func execute(db: Database) throws {
        for var transaction in forTransactions {
            //TODO: What if the transaction is actually a transfer?
            transaction.status = toStatus
            try transaction.save(db)
        }
    }
}

class SetTransactionTagsAction: BaseDatabaseAction {
    let forTransaction: Transaction
    let withTags: [Tag]
    
    init(transaction: Transaction, tags: [Tag]){
        self.forTransaction = transaction
        self.withTags = tags
    }
    
    override func execute(db: Database) throws {
        try TransactionTagMapping.filter(TransactionTagMapping.Columns.transactionID == forTransaction.id!).deleteAll(db)
        try withTags.forEach({ tag in
            var tTag = TransactionTagMapping(id: nil, transactionID: forTransaction.id!, tagID: tag.id!)
            try tTag.save(db)
        })
    }
}

class SetTransactionPostDateAction: BaseDatabaseAction {
    let forTransaction: Transaction
    let toDate: Date?
    
    init(transaction: Transaction, date: Date?){
        self.forTransaction = transaction
        self.toDate = date
    }
    
    override func execute(db: Database) throws {
        var transaction = forTransaction
        transaction.postDate = toDate
        try transaction.save(db)
    }
}
