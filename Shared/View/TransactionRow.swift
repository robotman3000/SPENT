//
//  TransactionRow.swift
//  macOS
//
//  Created by Eric Nims on 6/9/21.
//

import SwiftUI

struct TransactionRow: View {
    @State var transaction: Transaction
    
    struct Direction: View {
        @Binding var transaction: Transaction
        
        var body: some View {
            HStack {
                Text(transaction.getType().rawValue)
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Image(systemName: transaction.getType() == .Withdrawal ? "arrow.left" : "arrow.right")
                //Image(systemName: "arrow.right")
                
                Text(toString(transaction.sourceID))
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
    }
    
    struct Status: View {
        @Binding var status: Transaction.StatusTypes
        
        var body: some View {
            ZStack(alignment: .center){
                Circle().foregroundColor(.gray).frame(width: 60, height: 60)
                Text(status.rawValue.description)
                    .fontWeight(.heavy)
                    .font(.title)
            }
        }
    }
    
    var body: some View {
        HStack (alignment: .top){
            Status(status: $transaction.status)
            VStack (alignment: .leading){
                HStack {
                    VStack (alignment: .leading){
                        Text(transaction.payee ?? "N/A")
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        Text(transaction.date.transactionFormat)
                            .foregroundColor(.gray)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    Spacer()
                    VStack (alignment: .trailing){
                        Text(transaction.amount.currencyFormat)
                            .fontWeight(.bold)
                            .font(.title2)
                            .foregroundColor(transaction.getType() == .Withdrawal ? .red : .gray)
                        Direction(transaction: $transaction)
                    }
                }
                Text((transaction.memo).trunc(length: 60))
//                    HStack(){
//                        ForEach(transaction.tags){ tag in
//                            Text("[\(tag.name)]")
//                        }
//                    }
            }
        }
    }
}

//struct TransactionRow_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionRow()
//    }
//}
