//
//  SplitTransactionForm.swift
//  SPENT
//
//  Created by Eric Nims on 7/29/21.
//

import SwiftUI
import SwiftUIKit

struct SplitTransactionForm: View {
    @StateObject var model: SplitTransactionFormModel
    @State var selected: SplitMemberModel?
    
    var splitAmount: Int {
        get {
            var amnt = 0
            for m in model.members {
                amnt += NSDecimalNumber(string: m.amount.isEmpty ? "0" : m.amount).multiplying(by: 100).intValue
            }
            return amnt
        }
    }
    var headAmount: Int {
        get {
            return NSDecimalNumber(string: model.amount.isEmpty ? "0" : model.amount).multiplying(by: 100).intValue
        }
    }
    
    let onSubmit: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            EnumPicker(label: "Status", selection: $model.status, enumCases: Transaction.StatusTypes.allCases)
            
            Section(){
                DatePicker("Date", selection: $model.date, displayedComponents: [.date])
            }
            
            Section(header: EnumPicker(label: "Type", selection: $model.type, enumCases: [.Deposit, .Withdrawal]).pickerStyle(SegmentedPickerStyle())){
                BucketPicker(label: model.type == .Deposit ? "From" : "To", selection: $model.selectedBucket, choices: model.bucketChoices)
            }
            
            Section(){
                HStack{
                    Text("$") // TODO: Localize this text
                    TextField("Amount", text: $model.amount)
                }
                Text("\((headAmount - splitAmount).currencyFormat) remaining")
            }
            
            Section(){
                Button("+"){
                    if model.selectedBucket != nil {
                        let member = SplitMemberModel(transaction: nil, bucket: nil)
                        member.memo = "Hello World"
                        selected = member
                    } else {
                        print("Ignoring button click; Head bucket isn't set")
                    }
                }
                List(selection: $selected) {
                    if model.members.isEmpty {
                        Text("No Items")
                    }
                    
                    ForEach(model.members, id: \.self){ member in
                        Internal_SplitTransactionMemberListRow(model: member)
                    }
                }.labelStyle(DefaultLabelStyle())
                .popover(item: $selected) { member in
                    SplitMemberForm(model: member, choices: model.bucketChoices, onSubmit: { member in
                        print(member.bucket)
                        model.updateSplitMember(member)
                        selected = nil
                    }, onDelete: { member in
                        selected = nil
                        model.deleteSplitMember(member)
                    }, onCancel: {
                        selected = nil
                    })
                }
            }
            
            Section(){
                TextField("Payee", text: $model.payee)
                TextEditor(text: $model.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            }
            
        }.frame(minWidth: 300, minHeight: 400)
        .formFooter(model, onSubmit: onSubmit, onCancel: onCancel)
        //.frame(minWidth: 250, minHeight: 350)
    }
}

class SplitTransactionFormModel: FormModel {
    @Published var head: Transaction
    @Published var members: [SplitMemberModel] = []
    
    @Published var bucketChoices: [Bucket] = []
    @Published var selectedBucket: Bucket?
    
    @Published var payee: String
    @Published var memo: String
    @Published var type: Transaction.TransType = .Deposit
    @Published var amount: String = "0"
    @Published var date: Date
    @Published var status: Transaction.StatusTypes
    
    var deletedMembers: [Int64] = []
    
    init(head: Transaction){
        self.head = head
        payee = head.payee ?? ""
        memo = head.memo
        amount = NSDecimalNumber(value: head.amount).dividing(by: 100).stringValue
        date = head.date
        status = head.status
        // TODO: Source and dest posted
    }
    
    func updateSplitMember(_ member: SplitMemberModel){
       // First delete any old version
        deleteSplitMember(member, true)
        
        // Add the new member to the array
        members.append(member)
        print(member.bucket)
    }
    
    func deleteSplitMember(_ member: SplitMemberModel, _ isUpdate: Bool = false){
        var deleteIndex: Int? = nil
        var deletedId: Int64?
        for (index, element) in members.enumerated() {
            if element == member {
                deletedId = member.transaction?.id
                deleteIndex = index
                break
            }
        }
        
        if let index = deleteIndex {
            members.remove(at: index)
        }
        
        if !isUpdate && deletedId != nil {
            // Add the id to the list of deleted members
            deletedMembers.append(deletedId!)
        }
    }
    
    func loadState(withDatabase: DatabaseStore) throws {
        let rawMembers = withDatabase.database?.resolve(head.splitMembers) ?? []
        
        // Determine the split direction
        // We check only the first member because in a valid split all
        // the members will share the same source or destination account
        if let member = rawMembers.first {
            // The split has at least one member
            let bucket = withDatabase.database?.resolveOne(member.source)
            
            guard bucket != nil else {
                // This member is invalid since it's source was null
                throw FormInitializeError()
            }
            
            type = bucket!.isAccount() ? .Deposit : .Withdrawal
            
            let query = type == .Deposit ? member.source : member.destination
            selectedBucket = withDatabase.database?.resolveOne(query)
        }
        
        // Extract the relevant properties from the split members
        for rawMember in rawMembers {
            let bucket = withDatabase.database?.resolveOne(type == .Deposit ? rawMember.destination : rawMember.source)
            members.append(SplitMemberModel(transaction: rawMember, bucket: bucket))
        }
        
        bucketChoices = withDatabase.database?.resolve(Bucket.all()) ?? []
    }
    
    func validate() throws {
        // nil protection
        if amount.isEmpty || selectedBucket == nil || members.isEmpty {
            throw FormValidationError()
        }
        
        // selectedBucket must be an account
        if !selectedBucket!.isAccount() {
            throw FormValidationError()
        }
        
        for member in members {
            print(member.bucket)
            guard member.bucket != nil else {
                throw FormValidationError()
            }
            
            // the bucket of the members must be a bucket
            if member.bucket!.isAccount() {
                throw FormValidationError()
            }
            
            // The bucket of the member must be a child of the head account
            if member.bucket!.ancestorID! != selectedBucket!.id! {
                throw FormValidationError()
            }
        }
        // TODO: Prevent over spending a split
//        if (headAmount - splitAmount < 0){
//            throw FormValidationError()
//        }
    }
    
    func submit(withDatabase: DatabaseStore) throws {
        if payee.isEmpty {
            head.payee = nil
        } else {
            head.payee = payee
        }
        head.memo = memo
        head.status = status
        head.date = date
        
        // The split head must be inert except for the amount
        // which is used to calculcate the max split amount
        head.sourcePosted = nil
        head.destPosted = nil
        head.sourceID = nil
        head.destID = nil
        head.amount = NSDecimalNumber(string: amount).multiplying(by: 100).intValue
        
        var newSplit: [Transaction] = []
        newSplit.append(head)
        
        for index in members.indices {
            // If member is nil then create a new backing transaction
            var member: Transaction = members[index].transaction ?? Transaction.newSplitMember(head: head)
            
            // Ensure that the members adhear to the state rules
            member.status = head.status
            member.date = head.date
            member.sourcePosted = head.sourcePosted
            member.destPosted = head.destPosted
            member.group = head.group
            member.payee = head.payee
            
            if type == .Deposit {
                member.sourceID = selectedBucket!.id!
                member.destID = members[index].bucket!.id!
            } else {
                member.sourceID = members[index].bucket!.id!
                member.destID = selectedBucket!.id!
            }
            
            member.amount = NSDecimalNumber(string: members[index].amount).multiplying(by: 100).intValue
            member.memo = members[index].memo
            
            newSplit.append(member)
        }
        
        //TODO: Make these two operations run in a single transaction
        
        // Delete any deleted split members
        try withDatabase.deleteTransactions(deletedMembers)
        
        // Update the remaining
        try withDatabase.updateTransactions(&newSplit, onComplete: { print("Submit complete") })
    }
}

//struct SplitTransactionForm_Previews: PreviewProvider {
//    static var previews: some View {
//        SplitTransactionForm()
//    }
//}
