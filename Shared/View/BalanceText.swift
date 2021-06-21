//
//  BalanceText.swift
//  macOS
//
//  Created by Eric Nims on 6/10/21.
//

import SwiftUI

struct BalanceText: View {
    @Binding var bucket: Bucket
    @Query<BucketBalanceRequest> var bal: BucketBalance
    
    init(bucket: Binding<Bucket>){
        _bucket = bucket
        _bal = Query(BucketBalanceRequest(bucket.wrappedValue))
    }
    
    var body: some View {
        CurrencyText(balance: bal.availableInTree)
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
