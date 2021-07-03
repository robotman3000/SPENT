//
//  BalanceText.swift
//  macOS
//
//  Created by Eric Nims on 6/10/21.
//

import SwiftUI

struct CurrencyText: View {
    @Environment(\.colorScheme) var colorScheme
    let amount: Int
    
    var body: some View {
        Text(amount.currencyFormat)
            .foregroundColor(amount < 0 ? .red : (colorScheme == .light ? .black : .gray))
            .font(.headline)
            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
    }
}

struct CurrencyText_Previews: PreviewProvider {
    static var previews: some View {
        CurrencyText(amount: 100036)
        CurrencyText(amount: -25062)
    }
}
