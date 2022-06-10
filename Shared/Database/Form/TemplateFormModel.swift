//
//  TemplateFormModel.swift
//  SPENT
//
//  Created by Eric Nims on 6/8/22.
//

import GRDB
import SwiftUI

class TemplateFormModel: FormModel {
    fileprivate var dbtemplate: TransactionTemplate
    fileprivate var template: JSONTransactionTemplate = JSONTransactionTemplate(name: "", memo: "", amount: 0, tags: [])
    
    var bucketChoices: [Bucket] = []
    var accountChoices: [Account] = []
    
    @Published var account: Account?
    @Published var bucket: Bucket?
    
    @Published var name: String = ""
    @Published var type: Transaction.TransType = .Withdrawal
    @Published var amount: String = ""
    @Published var payee: String = ""
    @Published var memo: String = ""
    
    init(template: TransactionTemplate){
        self.dbtemplate = template
    }
    
    func loadState(withDatabase: Database) throws {
        bucketChoices = try Bucket.fetchAll(withDatabase)
        accountChoices = try Account.fetchAll(withDatabase)
        
        if let templateObj = try dbtemplate.decodeTemplate() {
            template = templateObj
            
            name = template.name
            payee = template.payee ?? ""
            memo = template.memo
            amount = NSDecimalNumber(value: abs(template.amount)).dividing(by: 100).stringValue
            type = template.amount < 0 ? .Withdrawal : .Deposit
            
            account = template.account != nil ? try Account.fetchOne(withDatabase, id: template.account!) : nil
            bucket = template.bucket != nil ? try Bucket.fetchOne(withDatabase, id: template.bucket!) : nil
        } else {
            throw FormInitializeError("Failed to decode template")
        }
    }
    
    func validate() throws {
        if amount.isEmpty || account == nil {
            throw FormValidationError("Form is missing required values")
        }
    }
    
    func submit(withDatabase: Database) throws {
        template.name = name
        template.account = account?.id
        template.bucket = bucket?.id
        
        if payee.isEmpty {
            template.payee = nil
        } else {
            template.payee = payee
        }
        
        template.memo = memo
        template.amount = abs(NSDecimalNumber(string: amount).multiplying(by: 100).intValue) * (type == .Withdrawal ? -1 : 1)
     
        let jsonData = try JSONEncoder().encode(template)
        dbtemplate.template = String(data: jsonData, encoding: .utf8) ?? ""
        try dbtemplate.save(withDatabase)
    }
}

