//
//  BalanceText.swift
//  macOS
//
//  Created by Eric Nims on 6/10/21.
//

import SwiftUI

struct CurrencyText: View {
    @Environment(\.colorScheme) var colorScheme
    let amount: Int?
    
    var body: some View {
        if let amnt = amount {
            Text(amnt.currencyFormat)
                .foregroundColor(amnt < 0 ? .red : (colorScheme == .light ? .black : .gray))
                .font(.headline)
                .fontWeight(.bold)
        } else {
            Text("$-.--")
                .foregroundColor(colorScheme == .light ? .black : .gray)
                .font(.headline)
                .fontWeight(.bold)
        }
    }
}

struct CurrencyText_Previews: PreviewProvider {
    static var previews: some View {
        CurrencyText(amount: 100036)
        CurrencyText(amount: -25062)
        CurrencyText(amount: nil)
        CurrencyText(amount: 0)
    }
}
