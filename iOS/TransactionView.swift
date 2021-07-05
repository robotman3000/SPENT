//
//  TransactionView.swift
//  iOS
//
//  Created by Eric Nims on 7/3/21.
//

import SwiftUI

struct TransactionView: View {
    @Environment(\.colorScheme) var colorScheme
    let data: TransactionData
    
    var body: some View {
        List{
            Section(header: Text("Status")){
                Text(data.transaction.status.getStringName())
                HStack {
                    Text("Amount: ")
                    Text(data.transaction.amount.currencyFormat)
                    .foregroundColor(data.transaction.type == .Withdrawal ? .red : (colorScheme == .light ? .black : .gray))
                }
            }
            
            Section(header: Text("Date")){
                Text(data.transaction.date.transactionFormat)
                Text("Posted: \(data.transaction.posted?.transactionFormat ?? "")")
            }
            
            Section(header: Text("Notes")){
                Text("Payee: \(data.transaction.payee ?? "")")
                Text(data.transaction.memo)
            }
            
            if !data.tags.isEmpty {
                Section(header: Text("Tags")){
                    HStack(){
                        ForEach(data.tags, id: \.self){ tag in
                            TransactionRow.Badge(text: tag.name, color: .gray)
                        }
                    }
                }
            }
        }.listStyle(GroupedListStyle())
        .toolbar(content: {
            EditButton()
        }).navigationTitle(data.transaction.type.getStringName())
    }
}

struct TransactionView_Previews: PreviewProvider {
    static var previews: some View {
        let bucket1 = Bucket(id: 1, name: "Account 1", parentID: nil, ancestorID: nil, memo: "", budgetID: nil)
        let bucket2 = Bucket(id: 1, name: "Account 2", parentID: nil, ancestorID: nil, memo: "", budgetID: nil)

        let t = Transaction.getRandomTransaction(withID: 1, withSource: bucket1.id, withDestination: bucket2.id, withGroup: nil)
        TransactionView(data: TransactionData(tags: [], source: bucket1, destination: bucket2, transaction: t))
    }
}
