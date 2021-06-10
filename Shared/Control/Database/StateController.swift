//
//  StateController.swift
//  iOS
//
//  Created by Eric Nims on 4/21/21.
//

import Foundation
import SwiftUI
import GRDB

class StateController: ObservableObject {
    let database: AppDatabase
    
    init(){
        database = AppDatabase.loadDB()
    }
    
    func initStore(onReady: () -> Void){
        onReady()
    }
}
