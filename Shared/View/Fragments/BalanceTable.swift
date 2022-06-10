//
//  BalanceTable.swift
//  SPENT
//
//  Created by Eric Nims on 4/22/21.
//

import SwiftUI
import GRDB
import GRDBQuery

struct AccountBalanceView: View {
    let account: Account
    @Query<AccountBalanceQuery> var balance: AccountBalance
    
    init(forAccount: Account){
        self._balance = Query(AccountBalanceQuery(account: forAccount), in: \.dbQueue)
        self.account = forAccount
    }
    
    var body: some View {
        VStack (spacing: 15){
            #if os(macOS)
            HStack (spacing: 3){
                Text("Balance of")
                Text(account.name).fontWeight(.bold)
            }
            #endif
            HStack (spacing: 15) {
                AccountBalanceView.BalanceView(text: "Posted", balance: balance.posted)
                AccountBalanceView.BalanceView(text: "Available", balance: balance.available)
            }
            HStack (spacing: 15) {
                AccountBalanceView.BalanceView(text: "Allocatable", balance: balance.allocatable)
                //AccountBalanceView.BalanceView(text: "Available in Tree", balance: 0)
            }
        }.padding()
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

//struct BalanceTable_Previews: PreviewProvider {
//    static var previews: some View {
//        BalanceTable(name: "Preview Test", posted: 10043, available: -3923, postedInTree: -38934, availableInTree: 20482)
//    }
//}
