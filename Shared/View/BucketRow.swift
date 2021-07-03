//
//  AccountsView.swift
//  iOS
//
//  Created by Eric Nims on 4/16/21.
//

import SwiftUI

struct BucketRow: View {
    
    let name: String
    let balance: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            HStack {
                Text(name)
                    .font(.headline)
                Spacer()
                CurrencyText(amount: balance)
                    .font(.headline)
                
            }
            //Text(model.bucket.memo)
        }
        .padding(.vertical, 5.0)
    }
}

struct BucketRow_Previews: PreviewProvider {
    static var previews: some View {
        BucketRow(name: "Test Bucket", balance: 24390)
    }
}

