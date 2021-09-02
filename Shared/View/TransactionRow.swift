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
    let contextBucket: Bucket
    
    @Binding var showTags: Bool

    struct Badge: View {
        let text: String
        let color: Color
        
        var body: some View {
            Text(text).fontWeight(.bold).frame(minWidth: 50)
                .font(.caption)
                .padding(3)
                .background(color)
                .cornerRadius(50)
        }
    }
    
    struct Direction: View {
        let sourceName: String
        let destinationName: String
        let direction: Transaction.TransType
        let contextDirection: Transaction.TransType
        
        var body: some View {
            HStack {
                if direction == .Transfer {
                    Text(contextDirection == .Deposit ? sourceName : destinationName)
                        .foregroundColor(.gray)
                        .font(.subheadline)
                        .fontWeight(.medium) 
                }
                
                Image(systemName: contextDirection == .Withdrawal ? "arrow.left" : "arrow.right")
                
                Text(contextDirection == .Deposit ? destinationName : sourceName)
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
    }
    
    struct Status: View {
        let status: Transaction.StatusTypes
        
        var body: some View {
            ZStack(alignment: .center){
                Circle().foregroundColor(.gray).frame(width: 40, height: 40)
                Text(status.rawValue.description)
                    .fontWeight(.heavy)
                    .font(.title)
            }
        }
    }
    
    var body: some View {
        let t = transactionData.transaction
        let cdirection = t.getType(convertTransfer: true, bucket: contextBucket.id)
        let direction = t.type
        
        VStack (alignment: .leading){
            HStack(alignment: .center){
                //TODO: This should be split into two views
                Spacer(minLength: 2)
                t.status.getIconView().frame(width: 16, height: 16)
                
                VStack{
                    Text(t.payee ?? t.type.getStringName())
                    Text(t.posted?.transactionFormat ?? t.date.transactionFormat)
                }.width(150)
                
                Spacer()
                VStack{
                    if t.group == nil {
                        Text(t.amount.currencyFormat).foregroundColor(cdirection == .Withdrawal ? .red : .gray)
                        Direction(sourceName: transactionData.source?.name ?? "NIL", destinationName: transactionData.destination?.name ?? "NIL", direction: direction, contextDirection: cdirection)
                    } else {
                        Text("Split \(Transaction.getSplitDirection(members: transactionData.splitMembers).getStringName())")
                        HStack{
                            if let trans = Transaction.getSplitMember(transactionData.splitMembers, bucket: contextBucket) {
                                Text("(\(trans.amount.currencyFormat))").foregroundColor(Transaction.getSplitDirection(members: transactionData.splitMembers) == .Withdrawal ? .red : .gray)
                            }
                            Text(Transaction.amountSum(transactionData.splitMembers).currencyFormat).foregroundColor(Transaction.getSplitDirection(members: transactionData.splitMembers) == .Withdrawal ? .red : .gray)
                        }
                    }
                }.width(200)
                
                
                
                Text(t.memo).frame(maxWidth: .infinity).help(t.memo)
            }
            if showTags {
                HStack{
                    ForEach(transactionData.tags, id: \.self){ tag in
                        Badge(text: tag.name, color: .gray)
                    }
                }
            }
            Spacer(minLength: 5)
            Divider()
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
