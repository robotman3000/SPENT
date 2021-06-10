//
//  BalanceTable.swift
//  SPENT
//
//  Created by Eric Nims on 4/22/21.
//

import SwiftUI

struct BalanceTable: View {
    
    var bucket: Bucket?
    
    var body: some View {
        VStack (spacing: 15){
            Text(bucket?.name ?? "No Selection")
            HStack (spacing: 15) {
                BalanceView(text: "Posted", balance: 67)
                BalanceView(text: "Posted in Tree", balance: 67)
            }
            HStack (spacing: 15) {
                BalanceView(text: "Available", balance: 67)
                BalanceView(text: "Available in Tree", balance: 67)
            }
        }
        //.background(Color.white)
        .padding()
    }
    
    struct BalanceView: View {
        
        let text: String
        @State var balance: Int
        
        var body: some View {
            VStack {
                HStack {
                    Image(systemName: "circle.fill")
                    Spacer()
                    Text(balance.currencyFormat)
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
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
