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

struct BucketListRow: View {
    @EnvironmentObject var store: DatabaseStore
    let id: Int64
    
    var body: some View {
        //Text("C").onAppear(perform: {print("appear C")})
        AsyncContentView(source: BucketFilter.publisher(store.getReader(), forID: id)) { model in
            Internal_BucketListRow(model: model)//.onAppear(perform: {print("appear D")})
        }
    }
}

private struct Internal_BucketListRow: View {
    let model: BucketModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            HStack {
                Text(model.bucket.name)
                    .font(.headline)
                Spacer()
                CurrencyText(amount: model.balance?.posted ?? 0)
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
