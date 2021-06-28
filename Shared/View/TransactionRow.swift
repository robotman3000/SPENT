//
//  TransactionRow.swift
//  macOS
//
//  Created by Eric Nims on 6/9/21.
//

import SwiftUI

struct TransactionRow: View {
    @EnvironmentObject var store: DatabaseStore
    @State var transaction: Transaction
    @State var bucket: Bucket
    @State var tags: [Tag]

    struct TagBadge: View {
        @State var tag: Tag
        
        var body: some View {
            Text(tag.name).padding(5).background(Color.gray).cornerRadius(25)
        }
    }
    
    struct Direction: View {
        @Binding var transaction: Transaction
        let sourceName: String
        let destName: String
        let direction: Transaction.TransType
        
        var body: some View {
            HStack {
//                Text(transaction.getType().rawValue)
//                    .foregroundColor(.gray)
//                    .font(.subheadline)
//                    .fontWeight(.medium)
                
                if transaction.type == .Transfer {
                    Text(direction == .Deposit ? sourceName : destName)
                        .foregroundColor(.gray)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Image(systemName: direction == .Withdrawal ? "arrow.left" : "arrow.right")
                //Image(systemName: "arrow.right")
                
                Text(direction == .Deposit ? destName : sourceName)
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
                Circle().foregroundColor(.gray).frame(width: 40, height: 40)
                Text(status.rawValue.description)
                    .fontWeight(.heavy)
                    .font(.title)
            }
        }
    }
    
    var body: some View {
        let sourceName = store.getBucketByID(transaction.sourceID)?.name ?? ""
        let destName = store.getBucketByID(transaction.destID)?.name ?? ""
        let direction = transaction.getType(convertTransfer: true, bucket: bucket.id!)
        
        HStack (alignment: .center){
            Status(status: $transaction.status)
            VStack (alignment: .leading){
                HStack {
                    VStack (alignment: .leading){
                        HStack {
                            Text(transaction.payee ?? transaction.type.rawValue)
                                .fontWeight(.bold)
                            HStack(){
                                ForEach(tags, id: \.self){ tag in
                                    TagBadge(tag: tag)
                                }
                            }
                        }
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
                            .foregroundColor(direction == .Withdrawal ? .red : .gray)
                        Direction(transaction: $transaction, sourceName: sourceName, destName: destName, direction: direction)
                    }
                }
                Text((transaction.memo).trunc(length: 70))
            }
        }
    }
}

//struct TransactionRow_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionRow()
//    }
//}
