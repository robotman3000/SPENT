//
//  BucketFormModel.swift
//  SPENT
//
//  Created by Eric Nims on 6/8/22.
//

import GRDB
import SwiftUI

class BucketFormModel: FormModel {
    fileprivate var bucket: Bucket
    
    @Published var name: String
    @Published var category: String
    
    init(bucket: Bucket){
        self.bucket = bucket
        self.name = bucket.name
        self.category = bucket.category
    }
    
    func loadState(withDatabase: Database) throws {}
    
    func validate() throws {
        if name.isEmpty {
            throw FormValidationError("Please provide a name")
        }
    }
    
    func submit(withDatabase: Database) throws {
        bucket.name = name
        bucket.category = category
        try bucket.save(withDatabase)
    }
}
