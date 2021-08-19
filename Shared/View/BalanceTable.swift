//
//  BalanceTable.swift
//  SPENT
//
//  Created by Eric Nims on 4/22/21.
//

import SwiftUI
import GRDB

struct BalanceTable: View {
    
    let name: String
    let posted: Int
    let available: Int
    let postedInTree: Int
    let availableInTree: Int
    var isNIL: Bool = false
    
    var body: some View {
        VStack (spacing: 15){
            if isNIL {
                //TODO: Remove the duplication of code
                HStack{
                    Text("No account selected")
                }
                HStack (spacing: 15) {
                    BalanceView(text: "Posted", balance: nil)
                    BalanceView(text: "Available", balance: nil)
                }
                HStack (spacing: 15) {
                    BalanceView(text: "Posted in Tree", balance: nil)
                    BalanceView(text: "Available in Tree", balance: nil)
                }
            } else {
                HStack (spacing: 3){
                    Text("Balance of")
                    Text(name).fontWeight(.bold)
                }
                HStack (spacing: 15) {
                    BalanceView(text: "Posted", balance: posted)
                    BalanceView(text: "Available", balance: available)
                }
                HStack (spacing: 15) {
                    BalanceView(text: "Posted in Tree", balance: postedInTree)
                    BalanceView(text: "Available in Tree", balance: availableInTree)
                }
            }
        }
        //.background(Color.white)
        .padding()
    }
    
    struct BalanceView: View {
        
        let text: String
        let balance: Int?
        
        var body: some View {
            VStack (alignment: .leading){
                HStack(){
                    Text(text)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    Spacer()
                }
                HStack(){
                    Spacer()
                    CurrencyText(amount: balance).frame(alignment: .trailing)
                }
            }.frame(width: 100, height: 30, alignment: .center)
            .padding()
            .background(Color.black.opacity(0.1))
            //.border(Color.black)
            //.cornerRadius(20)
            .clipShape(Rectangle()).cornerRadius(15)
        }
    }
}

struct BalanceTable_Previews: PreviewProvider {
    static var previews: some View {
        BalanceTable(name: "Preview Test", posted: 10043, available: -3923, postedInTree: -38934, availableInTree: 20482)
    }
}
