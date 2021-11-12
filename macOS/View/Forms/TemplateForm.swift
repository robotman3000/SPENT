//
//  TemplateForm.swift
//  macOS
//
//  Created by Eric Nims on 10/5/21.
//

import SwiftUI
import SwiftUIKit
import AudioToolbox

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
                        EnumPicker(label: "Type", selection: $model.type, enumCases: [.Deposit, .Withdrawal, .Transfer]).pickerStyle(SegmentedPickerStyle())
            ){
                if model.type == .Transfer || model.type == .Withdrawal {
                    BucketPicker(label: "From", selection: $model.selectedSource, choices: model.bucketChoices)
                }
                
                if model.type == .Transfer || model.type == .Deposit {
                    BucketPicker(label: "To", selection: $model.selectedDest, choices: model.bucketChoices)
                }
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
    fileprivate var dbtemplate: DBTransactionTemplate
    fileprivate var template: TransactionTemplate = TransactionTemplate(name: "", memo: "", amount: 0, tags: [])
    
    var bucketChoices: [Bucket] = []
    
    @Published var selectedSource: Bucket?
    @Published var selectedDest: Bucket?
    
    @Published var name: String = ""
    @Published var type: Transaction.TransType = .Withdrawal
    @Published var amount: String = ""
    @Published var payee: String = ""
    @Published var memo: String = ""
    
    init(template: DBTransactionTemplate){
        self.dbtemplate = template
    }
    
    func loadState(withDatabase: DatabaseStore) throws {
        if let templateObj = try dbtemplate.decodeTemplate() {
            template = templateObj
            
            payee = template.payee ?? ""
            type = ( (template.sourceBucket == template.destinationBucket) && template.sourceBucket != nil ? .Transfer : template.sourceBucket == nil ? .Deposit : .Withdrawal)
            amount = NSDecimalNumber(value: template.amount).dividing(by: 100).stringValue
            
            if let sourceID = template.sourceBucket {
                selectedSource = withDatabase.database?.resolveOne(Bucket.filter(id: sourceID))
            }
            
            if let destID = template.destinationBucket {
                selectedDest = withDatabase.database?.resolveOne(Bucket.filter(id: destID))
            }
        } else {
            throw FormInitializeError()
        }
    }
    
    func validate() throws {
        if amount.isEmpty || (selectedSource == nil && selectedDest == nil) {
            throw FormValidationError()
        }
    }
    
    func submit(withDatabase: DatabaseStore) throws {
        template.sourceBucket = selectedSource?.id
        template.destinationBucket = selectedDest?.id
        
        if type == .Deposit {
            template.sourceBucket = nil
        }
        
        if type == .Withdrawal {
            template.destinationBucket = nil
        }
        
        if payee.isEmpty {
            template.payee = nil
        } else {
            template.payee = payee
        }
        
        template.amount = NSDecimalNumber(string: amount).multiplying(by: 100).intValue
     
        let jsonData = try JSONEncoder().encode(template)
        dbtemplate.template = String(data: jsonData, encoding: .utf8) ?? ""
        
        try withDatabase.updateTemplate(&dbtemplate, onComplete: { print("Submit complete") })
    }
}

//struct TemplateForm_Previews: PreviewProvider {
//    static var previews: some View {
//        TemplateForm()
//    }
//}
