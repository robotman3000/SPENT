//
//  DatabaseManager.swift
//  macOS
//
//  Created by Eric Nims on 1/31/22.
//

import Foundation
import GRDB

// Core manager implementation; Copied from https://github.com/groue/GRDB.swift/blob/master/Documentation/GoodPracticesForDesigningRecordTypes.md#how-to-design-database-managers
class DatabaseManager: ObservableObject {
    let database: DatabaseQueue
    init(dbQueue: DatabaseQueue) {
        self.database = dbQueue
    }

    func action(_ action: DatabaseAction, onSuccess: () -> Void = {}, onError: (_: Error) -> Void = {_ in}) {
        self.action(actions: [action], onSuccess: onSuccess, onError: onError)
    }
    
    func action(action: DatabaseAction, onSuccess: () -> Void = {}, onError: (_: Error) -> Void = {_ in}) {
        self.action(actions: [action], onSuccess: onSuccess, onError: onError)
    }
    
    func action(actions: [DatabaseAction], onSuccess: () -> Void = {}, onError: (_ error: Error) -> Void = {_ in}) {
        do {
            try self.database.write { db in
                for action in actions {
                    try action.execute(db: db)
                }
            }
            onSuccess()
        } catch {
            print(error)
            onError(error)
        }
        //undoableAction(actions: actions, undoManager: nil, onSuccess: onSuccess, onError: onError)
    }
    
    func undoableAction(_ action: BaseUndoableDatabaseAction, _ undoManager: UndoManager?, onSuccess: () -> Void = {}, onError: (_: Error) -> Void = {_ in}) {
        self.undoableAction(actions: [action], undoManager: undoManager, onSuccess: onSuccess, onError: onError)
    }
    
    func undoableAction(action: BaseUndoableDatabaseAction, undoManager: UndoManager?, onSuccess: () -> Void = {}, onError: (_: Error) -> Void = {_ in}) {
        self.undoableAction(actions: [action], undoManager: undoManager, onSuccess: onSuccess, onError: onError)
    }
    
    func undoableAction(actions: [BaseUndoableDatabaseAction], undoManager: UndoManager?, onSuccess: () -> Void = {}, onError: (_ error: Error) -> Void = {_ in}) {
        
        do {
            try self.database.write { db in
                //undoManager?.beginUndoGrouping()
                for action in actions {
                    try action.executeUndoable(db: db, undoManager: undoManager)
                }
                //undoManager?.endUndoGrouping()
            }
            onSuccess()
        } catch {
            print(error)
            onError(error)
            undoManager?.removeAllActions()
        }
    }
}
