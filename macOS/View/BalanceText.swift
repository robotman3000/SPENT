//
//  BalanceText.swift
//  macOS
//
//  Created by Eric Nims on 6/10/21.
//

import SwiftUI

struct BalanceText: View {
    @EnvironmentObject var sc: StateController
    @Binding var bucket: Bucket
    
    var body: some View {
        CurrencyText(balance: getBalance())
    }
    
    func getBalance() -> Int {
        do {
            return try sc.database.getAvailableBalance(bucket)
        } catch {
            print(error)
        }
        return 0
    }
}

struct CurrencyText: View {
    let balance: Int
    
    var body: some View {
        Text(balance.currencyFormat)
            .foregroundColor(balance < 0 ? .red : .black)
    }
}
//
//struct BalanceText_Previews: PreviewProvider {
//    static var previews: some View {
//        BalanceText()
//    }
//}
