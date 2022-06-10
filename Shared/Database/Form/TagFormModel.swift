//
//  TagFormModel.swift
//  SPENT
//
//  Created by Eric Nims on 6/8/22.
//

import GRDB
import SwiftUI

class TagFormModel: FormModel {
    fileprivate var tag: Tag
    
    @Published var name: String
    
    init(tag: Tag){
        self.tag = tag
        self.name = tag.name
    }
    
    func loadState(withDatabase: Database) throws {}
    
    func validate() throws {
        if name.isEmpty {
            throw FormValidationError("Please provide a name")
        }
    }
    
    func submit(withDatabase: Database) throws {
        tag.name = name
        try tag.save(withDatabase)
    }
}
