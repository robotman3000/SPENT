//
//  TransactionView.swift
//  iOS
//
//  Created by Eric Nims on 7/3/21.
//

import SwiftUI

struct TransactionView: View {
    @Environment(\.editMode) var editMode
    @Environment(\.colorScheme) var colorScheme
    let status: Transaction.StatusTypes
    let direction: Transaction.TransType
    let contextDirection: Transaction.TransType
    let date: Date
    let posted: Date?
    let sourceName: String
    let destinationName: String
    let amount: Int
    let payee: String?
    let memo: String
    let tags: [Tag]
    @State var dataValue: String = ""
    
    var body: some View {
        List{
            Section(){
                HStack{
                    Text("Status")
                    Spacer()
                    Text(status.getStringName())
                }
                HStack {
                    Text("Amount")
                    Spacer()
                    Text(amount.currencyFormat)
                    .foregroundColor(contextDirection == .Withdrawal ? .red : (colorScheme == .light ? .black : .gray))
                }
            }
            
            Section(){
                HStack{
                    Text("Date")
                    Spacer()
                    Text(date.transactionFormat)
                }
                if let postedDate = posted {
                    HStack{
                        Text("Posted")
                        Spacer()
                        Text(postedDate.transactionFormat)
                    }
                }
            }
            
            Section(){
                if let thePayee = payee {
                    HStack{
                        Text("Payee")
                        Spacer()
                        Text(thePayee)
                    }
                }
                HStack {
                    if self.editMode!.wrappedValue == .active {
                        TextField("Memo", text: $dataValue)
                    } else {
                        Text(memo)
                    }
                }
            }
            
            if !tags.isEmpty {
                Section(header: Text("Tags")){
                    HStack(){
                        ForEach(tags, id: \.self){ tag in
                            TransactionRow.Badge(text: tag.name, color: .gray)
                        }
                    }
                }
            }
        }.listStyle(GroupedListStyle())
        .toolbar(content: {
            EditButton()
        }).navigationTitle(direction.getStringName())
    }
}

struct TransactionView_Previews: PreviewProvider {
    static var previews: some View {
        let bucket1 = Bucket(id: 1, name: "Account 1", parentID: nil, ancestorID: nil, memo: "", budgetID: nil)
        let bucket2 = Bucket(id: 1, name: "Account 2", parentID: nil, ancestorID: nil, memo: "", budgetID: nil)

        let t = Transaction.getRandomTransaction(withID: 1, withSource: bucket1.id, withDestination: bucket2.id, withGroup: nil)
        TransactionView(status: t.status, direction: t.type, contextDirection: .Withdrawal, date: t.date, posted: t.date, sourceName: bucket1.name, destinationName: bucket2.name, amount: 5324, payee: "The Bank", memo: "Some memo", tags: [])
    }
}
