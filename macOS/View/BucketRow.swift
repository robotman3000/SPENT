//
//  AccountsView.swift
//  iOS
//
//  Created by Eric Nims on 4/16/21.
//

import SwiftUI

struct BucketRow: View {
    let bucket: Bucket
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            HStack {
                Text(bucket.name)
                    .font(.headline)
                Spacer()
                Text(6038.currencyFormat)
                    .font(.headline)
            }
            //Text("Parent ID: \(bucket.parentID ?? -1)")
            //Text("Memo: \(bucket.memo)")
        }
        .padding(.vertical, 5.0)
    }
}
