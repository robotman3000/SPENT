//
//  SplitMemberForm.swift
//  macOS
//
//  Created by Eric Nims on 7/30/21.
//

import SwiftUI
import SwiftUIKit

struct SplitMemberForm: View {
    @StateObject var model: SplitMemberModel
    let choices: [Bucket]
    
    let onSubmit: (_ model: SplitMemberModel) -> Void
    let onDelete: (_ model: SplitMemberModel) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            HStack{
                Text("$") // TODO: Localize this text
                TextField("Amount", text: $model.amount)
            }

            BucketPicker(label: "Bucket", selection: $model.bucket, choices: choices)
            Section(){
                TextEditor(text: $model.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            }
            
            Section{
                HStack{
                    Button("Cancel", action: {
                        onCancel()
                    })
                    
                    Button("Delete", action: {
                        onDelete(model)
                    })
                    
                    Spacer()
                    
                    Button("Done", action: {
                        onSubmit(model)
                    })
                }
            }
        }.frame(minWidth: 250, minHeight: 150).padding()
    }
}

class SplitMemberModel: ObservableObject, Identifiable, Equatable, Hashable {
    static func == (lhs: SplitMemberModel, rhs: SplitMemberModel) -> Bool {
        var result = true
        if (lhs.id != rhs.id){
            result = false
        }
        
        if (lhs.amount != rhs.amount){
            result = false
        }
        
        if (lhs.bucket != rhs.bucket){
            result = false
        }
        
        if (lhs.memo != rhs.memo){
            result = false
        }
        return result
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(amount)
        hasher.combine(bucket)
        hasher.combine(memo)
    }
    
    let transaction: Transaction?
    let id = UUID()
    @Published var amount: String
    @Published var bucket: Bucket? {
        didSet {
            self.bucketID = bucket?.id
        }
    }
    @Published var memo: String
    private(set) var bucketID: Int64?
    
    init(transaction: Transaction?, bucket: Bucket?){
        self.transaction = transaction
        self.amount = NSDecimalNumber(value: transaction?.amount ?? 0).dividing(by: 100).stringValue
        self.bucket = bucket
        self.bucketID = bucket?.id
        self.memo = transaction?.memo ?? ""
        
    }
}

//struct SplitMemberForm_Previews: PreviewProvider {
//    static var previews: some View {
//        SplitMemberForm()
//    }
//}
