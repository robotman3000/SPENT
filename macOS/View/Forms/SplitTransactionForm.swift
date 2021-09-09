//
//  SplitTransactionForm.swift
//  SPENT
//
//  Created by Eric Nims on 7/29/21.
//

import SwiftUI
import SwiftUIKit

struct SplitTransactionForm: View {
    @StateObject fileprivate var aContext: AlertContext = AlertContext()
    @EnvironmentObject fileprivate var dbStore: DatabaseStore
    @State var head: Transaction
    
    @Query(BucketRequest()) var bucketChoices: [Bucket]
    @State var splitMembers: [Transaction]

    @State var selectedBucket: Bucket?
    @State fileprivate var payee: String = ""
    @State fileprivate var initType: Transaction.TransType = .Deposit
    @State fileprivate var transType: Transaction.TransType = .Deposit
    @State fileprivate var amount: String = "0"
    
    var splitAmount: Int {
        get {
            var amnt = 0
            for m in splitMembers {
                amnt += m.amount
            }
            return amnt
        }
    }
    var headAmount: Int {
        get {
            return NSDecimalNumber(string: amount.isEmpty ? "0" : amount).multiplying(by: 100).intValue
        }
    }
    
    let onSubmit: (_ data: inout [Transaction]) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            EnumPicker(label: "Status", selection: $head.status, enumCases: Transaction.StatusTypes.allCases)
            
            Section(){
                DatePicker("Date", selection: $head.date, displayedComponents: [.date])
            }
            
            Section(header: EnumPicker(label: "Type", selection: $transType, enumCases: [.Deposit, .Withdrawal]).pickerStyle(SegmentedPickerStyle())){
                BucketPicker(label: transType == .Deposit ? "From" : "To", selection: $selectedBucket, choices: bucketChoices)
            }
            
            Section(){
                HStack{
                    Text("$") // TODO: Localize this text
                    TextField("Amount", text: $amount)
                }
                Text("\((headAmount - splitAmount).currencyFormat) remaining")
            }
            
            Section(){
                SplitTransactionMemberList(head: head, splits: $splitMembers, splitDirection: initType).labelStyle(DefaultLabelStyle())
            }//.frameSize()
            
            Section(){
                TextField("Payee", text: $payee)
                TextEditor(text: $head.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            }
            
        }.frame(minWidth: 300, minHeight: 400)
        .onAppear { loadState() }
        .toolbar(content: {
            ToolbarItem(placement: .confirmationAction){
                Button("Done", action: {
                    if storeState() {
                        var newSplit: [Transaction] = []
                        
                        newSplit.append(head)
                        newSplit.append(contentsOf: splitMembers)
                        
                        onSubmit(&newSplit)
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
        }).frame(minWidth: 250, minHeight: 350)
        .alert(context: aContext)
    }
    
    func loadState(){
        payee = head.payee ?? ""
        
        // Load the split members
        initType = Transaction.getSplitDirection(members: splitMembers)
        transType = initType
        
        amount = NSDecimalNumber(value: head.amount).dividing(by: 100).stringValue
        
        if let member = splitMembers.first {
            let query = transType.opposite == .Deposit ? member.destination : member.source
            selectedBucket = dbStore.database?.resolveOne(query)
        }
    }
    
    func storeState() -> Bool {
        if amount.isEmpty || selectedBucket == nil || splitMembers.isEmpty {
            return false
        }
        
        // Prevent over spending a split
        if (headAmount - splitAmount < 0){
            return false
        }
        
        if payee.isEmpty {
            head.payee = nil
        } else {
            head.payee = payee
        }
        
        // The split head must be inert except for the amount
        // which is used to calculcate the max split amount
        head.posted = nil
        head.sourceID = nil
        head.destID = nil
        head.amount = NSDecimalNumber(string: amount).multiplying(by: 100).intValue
        
        print(splitMembers)
        for index in splitMembers.indices {
            // Ensure that the members adhear to the state rules
            splitMembers[index].status = head.status
            splitMembers[index].date = head.date
            splitMembers[index].posted = head.posted
            splitMembers[index].group = head.group
            splitMembers[index].payee = head.payee
            
            if transType != initType {
                // Swap the sources and destinations
                let oldSource = splitMembers[index].sourceID
                let oldDest = splitMembers[index].destID
                splitMembers[index].sourceID = oldDest
                splitMembers[index].destID = oldSource
            }
            
            if transType == .Deposit {
                splitMembers[index].sourceID = selectedBucket!.id!
            } else {
                splitMembers[index].destID = selectedBucket!.id!
            }
        }
        print("====")
        print(splitMembers)

        return true
    }
}

//struct SplitTransactionForm_Previews: PreviewProvider {
//    static var previews: some View {
//        SplitTransactionForm()
//    }
//}
