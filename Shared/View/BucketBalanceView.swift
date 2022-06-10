//
//  BucketBalanceView.swift
//  macOS
//
//  Created by Eric Nims on 5/13/22.
//

import SwiftUI
import GRDBQuery

struct BucketBalanceView: View {
    @Query<BucketBalanceQuery> var balance: BucketBalance?
    
    init(forAccount: Account, forBucket: Bucket){
        self._balance = Query(BucketBalanceQuery(forAccount: forAccount, forBucket: forBucket), in: \.dbQueue)
    }
    
    var body: some View {
        VStack {
            // Bucket posted and available balance
            Text("Available: \(balance?.available.currencyFormat ?? "NIL")").foregroundColor(balance?.available ?? 0 < 0 ? .red : .black)
            Text("Posted: \(balance?.posted.currencyFormat ?? "NIL")").foregroundColor(balance?.posted ?? 0 < 0 ? .red : .black)
            
            //count open(pending, submitted, complete), planned(uninit)
            
        }
    }
}


//struct BucketBalanceView_Previews: PreviewProvider {
//    static var previews: some View {
//        BucketBalanceView()
//    }
//}
