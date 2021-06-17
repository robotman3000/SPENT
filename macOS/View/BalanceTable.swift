//
//  BalanceTable.swift
//  SPENT
//
//  Created by Eric Nims on 4/22/21.
//

import SwiftUI

struct BalanceTable: View {
    @Environment(\.appDatabase) private var database: AppDatabase?
    @Binding var bucket: Bucket?
    
    var body: some View {
        VStack (spacing: 15){
            Text(bucket?.name ?? "No Selection")

            let bal = database!.getBucketBalance(bucket)
            HStack (spacing: 15) {
                BalanceView(text: "Posted", balance: bal.posted)
                BalanceView(text: "Posted in Tree", balance: bal.postedInTree)
            }
            HStack (spacing: 15) {
                BalanceView(text: "Available", balance: bal.available)
                BalanceView(text: "Available in Tree", balance: bal.availableInTree)
            }
        }
        //.background(Color.white)
        .padding()
    }
    
    struct BalanceView: View {
        
        let text: String
        let balance: Int
        
        var body: some View {
            VStack {
                HStack {
                    Image(systemName: "circle.fill")
                    Spacer()
                    CurrencyText(balance: balance)
                        .font(.headline)
                        //.fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                }
                HStack {
                    Text(text)
                        .font(.caption)
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
            .padding()
            .background(Color.black.opacity(0.1))
            //.border(Color.black)
            //.cornerRadius(20)
            .clipShape(Rectangle()).cornerRadius(15)
        }
    }
}

//struct BalanceTable_Previews: PreviewProvider {
//    static var previews: some View {
//        BalanceTable(bucket: Bucket(id: 10, name: "Test Bucket"))
//    }
//}
