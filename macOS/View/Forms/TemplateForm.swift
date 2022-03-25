//
//  TemplateForm.swift
//  macOS
//
//  Created by Eric Nims on 10/5/21.
//

import SwiftUI
import SwiftUIKit
import GRDB

struct TemplateForm: View {
    @StateObject var model: TemplateFormModel
    
    let onSubmit: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            TextField("Name", text: $model.name)
            
            HStack{
                Text("$") // TODO: Localize this text
                TextField("Amount", text: $model.amount)
            }

            Section(header:
                        EnumPicker(label: "Type", selection: $model.type, enumCases: [.Deposit, .Withdrawal]).pickerStyle(SegmentedPickerStyle())
            ){

                HStack {
                    BucketPicker(label: "Bucket", selection: $model.bucket, choices: model.bucketChoices)
                    Button("X"){
                        model.bucket = nil
                    }
                }
                AccountPicker(label: model.type == .Withdrawal ? "From" : "To", selection: $model.account, choices: model.accountChoices)
            }
            
            Section(){
                TextField("Payee", text: $model.payee)
                TextEditor(text: $model.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            }
            
        }.frame(minWidth: 250, minHeight: 300)
        .formFooter(model, onSubmit: onSubmit, onCancel: onCancel)
    }
}

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

//struct TemplateForm_Previews: PreviewProvider {
//    static var previews: some View {
//        TemplateForm()
//    }
//}
