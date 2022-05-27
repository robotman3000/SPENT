//
//  BucketListRow.swift
//  macOS
//
//  Created by Eric Nims on 2/19/22.
//

import SwiftUI

struct BucketListRow: View {
    let forBucket: BucketInfo
    
    var body: some View {
        HStack {
            Text(forBucket.bucket.displayName)
            Spacer()
            Text(forBucket.balance.available.currencyFormat).foregroundColor(forBucket.balance.available < 0 ? .red : .gray)
        }
    }
}

//struct BucketListRow_Previews: PreviewProvider {
//    static var previews: some View {
//        BucketListRow()
//    }
//}
