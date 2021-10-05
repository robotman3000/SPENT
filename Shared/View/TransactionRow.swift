//
//  TransactionRow.swift
//  macOS
//
//  Created by Eric Nims on 6/9/21.
//

import SwiftUI

struct TransactionRow: View {
    @Environment(\.colorScheme) var colorScheme
    let transactionData: TransactionData
    @Binding var showTags: Bool
    @Binding var showMemo: Bool
    
    var body: some View {
        let td = transactionData
        let t = td.transaction
        
        VStack (alignment: .leading){
            Spacer()
            HStack(alignment: .center){
                //TODO: This should be split into two views
                Spacer(minLength: 2)
                t.status.getIconView().frame(width: 16, height: 16)
                
                // Running Balance
                HStack{
                    if let bal = transactionData.balance {
                        Text((bal.postedRunning ?? -1).currencyFormat)
                    } else {
                        Text("")
                    }
                    Spacer()
                }.frame(minWidth: 70, maxWidth: 80)
                
                // Payee or Type
                HStack{
                    Text(td.balance == nil ? "Allocation" : t.payee ?? t.type.getStringName())
                    Spacer()
                }.frame(minWidth: 100, maxWidth: 150)
                    
                // Date
                HStack {
                    if let bal = td.balance  {
                        Text(bal.date.transactionFormat)
                    } else {
                        Text("")
                    }
                    Spacer()
                }.frame(minWidth: 90, maxWidth: 90)
                
                // Amount
                HStack {
                    Spacer()
                    //Text(bal.amount.currencyFormat)
                    if let trans = td.splitMember {
                        Text(trans.amount.currencyFormat).foregroundColor(td.splitType == .Withdrawal ? .red : .gray)
                    } else {
                        Text(td.amountFormatted).foregroundColor(td.contextType == .Withdrawal ? .red : .gray)
                    }
                }.frame(minWidth: 80, maxWidth: 80)
                
                // Bucket
                HStack {
                    if td.splitMember != nil {
                        Text("(\(td.amountFormatted))").foregroundColor(td.splitType == .Withdrawal ? .red : .gray)
                    }
                    VStack{
                        if t.group == nil {
                            let sName = transactionData.source?.name ?? "NIL"
                            let dName = transactionData.destination?.name ?? "NIL"
                            
                            HStack {
                                if t.type == .Transfer {
                                    Text(td.contextType == .Deposit ? sName : dName)
                                        .foregroundColor(.gray)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                Image(systemName: td.contextType == .Withdrawal ? "arrow.left" : "arrow.right")
                                
                                Text(td.contextType == .Deposit ? dName : sName)
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        } else {
                            Text("Split \(td.splitType.getStringName())")
                        }
                    }
                    Spacer()
                }.frame(minWidth: 80, maxWidth: .infinity)
                
                
            }
            
            // Tags and Memo
            if showMemo || showTags {
                HStack {
                    Text("").frame(width: 16)
                    if showMemo {
                        Text(t.memo).help(t.memo)
                    }
                    Spacer()
                    if showTags {
                        ForEach(transactionData.tags, id: \.self){ tag in
                            Text(tag.name).fontWeight(.bold).frame(minWidth: 50)
                                .font(.caption)
                                .padding(3)
                                .background(Color.gray)
                                .cornerRadius(50)
                        }
                    }
                }
            }
//
//                Spacer(minLength: 5)

//
//            Divider().frame(height: 5)
            Spacer()
        }
    }
}

//struct TransactionRow_Previews: PreviewProvider {
//    static var previews: some View {
//        let bucket1 = Bucket(id: 1, name: "Account 1", parentID: nil, ancestorID: nil, memo: "", budgetID: nil)
//        let bucket2 = Bucket(id: 1, name: "Account 2", parentID: nil, ancestorID: nil, memo: "", budgetID: nil)
//
//        let t = Transaction.getRandomTransaction(withID: 1, withSource: bucket1.id, withDestination: bucket2.id, withGroup: nil)
//        TransactionRow(status: t.status, direction: t.type, contextDirection: .Deposit, date: t.date, sourceName: bucket1.name, destinationName: bucket2.name, amount: 5324, payee: nil, memo: "Some memo", tags: [])
//
//        TransactionRow.Badge(text: "Test", color: .gray)
//    }
//}
