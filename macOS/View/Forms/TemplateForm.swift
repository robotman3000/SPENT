//
//  TemplateForm.swift
//  macOS
//
//  Created by Eric Nims on 10/5/21.
//

import SwiftUI
import SwiftUIKit

struct TemplateForm: View {
    @StateObject fileprivate var aContext: AlertContext = AlertContext()
    @EnvironmentObject fileprivate var dbStore: DatabaseStore
    @State var dbtemplate: DBTransactionTemplate
    @State var template: TransactionTemplate = TransactionTemplate(name: "", memo: "", amount: 0, tags: [])
    
    var bucketChoices: [Bucket] = []
    
    @State var selectedSource: Bucket?
    @State var selectedDest: Bucket?
    
    @State fileprivate var payee: String = ""
    @State fileprivate var transType: Transaction.TransType = .Withdrawal
    @State fileprivate var amount: String = ""
    
    let onSubmit: (_ data: inout DBTransactionTemplate) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            TextField("Name", text: $template.name)
            
            HStack{
                Text("$") // TODO: Localize this text
                TextField("Amount", text: $amount)
            }

            Section(header:
                        EnumPicker(label: "Type", selection: $transType, enumCases: [.Deposit, .Withdrawal, .Transfer]).pickerStyle(SegmentedPickerStyle())
            ){
                if transType == .Transfer || transType == .Withdrawal {
                    BucketPicker(label: "From", selection: $selectedSource, choices: bucketChoices)
                }
                
                if transType == .Transfer || transType == .Deposit {
                    BucketPicker(label: "To", selection: $selectedDest, choices: bucketChoices)
                }
            }
            
            Section(){
                TextField("Payee", text: $payee)
                TextEditor(text: $template.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            }
            
        }.frame(minWidth: 250, minHeight: 300)
        .onAppear { loadState() }
        .toolbar(content: {
            ToolbarItem(placement: .confirmationAction){
                Button("Done", action: {
                    if storeState() {
                        onSubmit(&dbtemplate)
                    } else {
                        aContext.present(AlertKeys.message(message: "Invalid Input"))
                    }
                })
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: {
                    onCancel()
                })
            }
        })
        .alert(context: aContext)
    }
    
    func loadState(){
        do {
            if let templateObj = try dbtemplate.decodeTemplate() {
                template = templateObj
                
                payee = template.payee ?? ""
                transType = ( (template.sourceBucket == template.destinationBucket) && template.sourceBucket != nil ? .Transfer : template.sourceBucket == nil ? .Deposit : .Withdrawal)
                amount = NSDecimalNumber(value: template.amount).dividing(by: 100).stringValue
                
                if let sourceID = template.sourceBucket {
                    selectedSource = dbStore.database?.resolveOne(Bucket.filter(id: sourceID))
                }
                
                if let destID = template.destinationBucket {
                    selectedDest = dbStore.database?.resolveOne(Bucket.filter(id: destID))
                }
            } else {
                print("Unknown error occured while decoding template")
            }
        } catch {
            print(error.localizedDescription)
            aContext.present(AlertKeys.message(message: "Failed to decode template"))
            onCancel()
        }
    }
    
    func storeState() -> Bool {
        if amount.isEmpty || (selectedSource == nil && selectedDest == nil) {
            return false
        }
        
        template.sourceBucket = selectedSource?.id
        template.destinationBucket = selectedDest?.id
        
        if transType == .Deposit {
            template.sourceBucket = nil
        }
        
        if transType == .Withdrawal {
            template.destinationBucket = nil
        }
        
        if payee.isEmpty {
            template.payee = nil
        } else {
            template.payee = payee
        }
        
        template.amount = NSDecimalNumber(string: amount).multiplying(by: 100).intValue
        
        
        do {
            let jsonData = try JSONEncoder().encode(template)
            dbtemplate.template = String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            print(error)
            aContext.present(AlertKeys.message(message: "Failed to encode template"))
            return false
        }
        
        return true
    }
}

//struct TemplateForm_Previews: PreviewProvider {
//    static var previews: some View {
//        TemplateForm()
//    }
//}
