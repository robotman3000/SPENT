//
//  BucketListRow.swift
//  SPENT
//
//  Created by Eric Nims on 10/16/21.
//

import SwiftUI
import Combine
import GRDB
import SwiftUIKit

struct AccountListRow: View {
    let model: AccountInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            HStack {
                Text(model.account.name)
                    .font(.headline)
                Spacer()
                CurrencyText(amount: model.balance.posted)
                    .font(.headline)
                
            }
            //Text(model.bucket.memo)
        }
        .padding(.vertical, 5.0)
    }
}

//struct BucketListRow_Previews: PreviewProvider {
//    static var previews: some View {
//        BucketListRow(name: "Test Bucket", balance: 24390)
//    }
//}
