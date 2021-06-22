//
//  TransactionRow.swift
//  macOS
//
//  Created by Eric Nims on 6/9/21.
//

import SwiftUI

struct TransactionRow: View {
    @State var transaction: Transaction
    @State var bucket: Bucket
    @Environment(\.appDatabase) private var database: AppDatabase?
    
    struct Direction: View {
        @Binding var transaction: Transaction
        @State var bucketID: Int64
        
        var body: some View {
            HStack {
//                Text(transaction.getType().rawValue)
//                    .foregroundColor(.gray)
//                    .font(.subheadline)
//                    .fontWeight(.medium)
                
                let transDirection = transaction.getType(convertTransfer: true, bucket: bucketID)
                
                if transaction.getType() == .Transfer {
                    Text(transDirection == .Deposit ? toString(transaction.sourceID) : toString(transaction.destID))
                        .foregroundColor(.gray)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Image(systemName: transDirection == .Withdrawal ? "arrow.left" : "arrow.right")
                //Image(systemName: "arrow.right")
                
                Text(transDirection == .Deposit ? toString(transaction.destID) : toString(transaction.sourceID))
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
                        Text(transaction.payee ?? transaction.getType().rawValue)
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
                            .foregroundColor(transaction.getType(convertTransfer: true, bucket: bucket.id!) == .Withdrawal ? .red : .gray)
                        Direction(transaction: $transaction, bucketID: bucket.id!)
                    }
                }
                Text((transaction.memo).trunc(length: 70))
//                    HStack(){
//                        ForEach(transaction.tags.fetchAll(database!.databaseReader)){ tag in
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
