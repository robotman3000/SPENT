//
//  SplitTransactionForm.swift
//  SPENT
//
//  Created by Eric Nims on 7/29/21.
//

import SwiftUI
import SwiftUIKit
import GRDB

struct SplitTransactionForm: View {
    @StateObject var model: SplitTransactionFormModel
    @State var selected: SplitMemberFormModel?
    
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
                AccountPicker(label: model.type == .Deposit ? "From" : "To", selection: $model.selectedAccount, choices: model.accountChoices)
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
                    selected = SplitMemberFormModel(splitUUID: model.splitUUID)
                }
                List(selection: $selected) {
                    if model.members.filter({ $0.editStatus != .databaseDeleted }).isEmpty {
                        Text("No Items")
                    }
                    
                    ForEach(model.members.filter({ $0.editStatus != .databaseDeleted }), id: \.self){ member in
                        Internal_SplitTransactionMemberListRow(model: member)
                    }
                }.labelStyle(DefaultLabelStyle())
                .popover(item: $selected) { member in
                    SplitMemberForm(model: member, choices: model.bucketChoices, onSubmit: { member in
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
                TextEditor(text: $model.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            }
            
        }.frame(minWidth: 300, minHeight: 400)
        .formFooter(model, onSubmit: onSubmit, onCancel: onCancel)
        //.frame(minWidth: 250, minHeight: 350)
    }
}

//struct SplitTransactionForm_Previews: PreviewProvider {
//    static var previews: some View {
//        SplitTransactionForm()
//    }
//}
