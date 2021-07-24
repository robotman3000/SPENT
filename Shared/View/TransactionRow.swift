//
//  TransactionRow.swift
//  macOS
//
//  Created by Eric Nims on 6/9/21.
//

import SwiftUI

struct TransactionRow: View {
    @Environment(\.colorScheme) var colorScheme
    let status: Transaction.StatusTypes
    let direction: Transaction.TransType
    let contextDirection: Transaction.TransType
    let date: Date
    let sourceName: String
    let destinationName: String
    let amount: Int
    let payee: String?
    let memo: String
    let tags: [Tag]
    

    struct Badge: View {
        let text: String
        let color: Color
        
        var body: some View {
            Text(text).padding(5).background(color).cornerRadius(25)
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
        HStack (alignment: .center){
            status.getIconView().frame(width: 40, height: 40)
            //Status(status: status)
            VStack (alignment: .leading){
                HStack {
                    VStack (alignment: .leading){
                        HStack {
                            Text(payee ?? direction.rawValue)
                                .fontWeight(.bold)
                            HStack(){
                                ForEach(tags, id: \.self){ tag in
                                    Badge(text: tag.name, color: .gray)
                                }
                            }
                        }
                        Text(date.transactionFormat)
                            .foregroundColor(.gray)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    Spacer()
                    VStack (alignment: .trailing){
                        Text(amount.currencyFormat)
                            .fontWeight(.bold)
                            .font(.title2)
                            .foregroundColor(direction == .Withdrawal ? .red : (colorScheme == .light ? .black : .gray))
                        Direction(sourceName: sourceName,
                                  destinationName: destinationName,
                                  direction: direction,
                                  contextDirection: contextDirection)
                    }
                }
                Text(memo.trunc(length: 70))
            }
        }
    }
}

struct TransactionRow_Previews: PreviewProvider {
    static var previews: some View {
        let bucket1 = Bucket(id: 1, name: "Account 1", parentID: nil, ancestorID: nil, memo: "", budgetID: nil)
        let bucket2 = Bucket(id: 1, name: "Account 2", parentID: nil, ancestorID: nil, memo: "", budgetID: nil)
        
        let t = Transaction.getRandomTransaction(withID: 1, withSource: bucket1.id, withDestination: bucket2.id, withGroup: nil)
        TransactionRow(status: t.status, direction: t.type, contextDirection: .Deposit, date: t.date, sourceName: bucket1.name, destinationName: bucket2.name, amount: 5324, payee: nil, memo: "Some memo", tags: [])
    }
}
