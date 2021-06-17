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
    
    init(_ fileConfig: FileDocumentConfiguration<SPENTDatabaseDocument>){
        self.database = fileConfig.document.database
    }
    
    func initStore(onReady: () -> Void){
        onReady()
    }
    
    func getBucketBalance(_ bucket: Bucket?) -> BucketBalance {
        var pb = 0
        var ptb = 0
        var ab = 0
        var atb = 0
        
        do {
        if bucket != nil {
            // TODO: Calculate the balance
            pb = try database.getPostedBalance(bucket!)
            ab = try database.getAvailableBalance(bucket!)
            ptb = try database.getPostedTreeBalance(bucket!)
            atb = try database.getAvailableTreeBalance(bucket!)
        }
        } catch {
            print("Error while calculating balance for bucket")
            print(error)
        }
        
        return BucketBalance(posted: pb, available: ab, postedInTree: ptb, availableInTree: atb)
    }
}

struct BucketBalance {
    let posted: Int
    let available: Int
    let postedInTree: Int
    let availableInTree: Int
}
