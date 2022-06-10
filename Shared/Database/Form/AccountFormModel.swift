//
//  AccountFormModel.swift
//  SPENT
//
//  Created by Eric Nims on 6/8/22.
//

import GRDB
import SwiftUI

class AccountFormModel: FormModel {
    fileprivate var account: Account
    
    @Published var name: String
    
    init(_ account: Account){
        self.account = account
        self.name = account.name
    }
    
    func loadState(withDatabase: Database) throws {}
    
    func validate() throws {
        if name.isEmpty {
            throw FormValidationError("Please provide a name")
        }
    }
    
    func submit(withDatabase: Database) throws {
        account.name = name
        try account.save(withDatabase)
    }
}
