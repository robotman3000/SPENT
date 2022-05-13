//
//  AccountBucketToolbar.swift
//  macOS
//
//  Created by Eric Nims on 5/13/22.
//

import SwiftUI
import GRDBQuery

struct AccountBucketToolbar: View {
    @EnvironmentObject var globalState: GlobalState
    let account: Account
    let bucket: Bucket?
    @Query<AccountBuckets> var buckets: [BucketInfo]
    @State private var showingManager: Bool = false
    
    init(forAccount: Account, withBucket: Bucket? = nil){
        self._buckets = Query(AccountBuckets(forAccount: forAccount), in: \.dbQueue)
        self.account = forAccount
        self.bucket = withBucket
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Toggle("Show Allocations", isOn: $globalState.showAllocations)
                Toggle("Show Cleared", isOn: $globalState.showCleared)
            }
            VStack {
                EnumPicker(label: "Sort By", selection: $globalState.sorting, enumCases: [.byPostDate, .byEntryDate, .byAmount, .byBucket, .byMemo, .byPayee, .byStatus])
                EnumPicker(label: "", selection: $globalState.sortDirection, enumCases: Transaction.OrderDirection.allCases).pickerStyle(SegmentedPickerStyle())
            }.frame(maxWidth: 200)
            VStack {
                EnumPicker(label: "", selection: $globalState.transRowMode, enumCases: TransactionRowMode.allCases).pickerStyle(SegmentedPickerStyle())
            }.frame(maxWidth: 200)
            //TextField("", text: $stringFilter)
            Spacer()
            if let bucket = bucket {
                BucketBalanceView(forAccount: account, forBucket: bucket)
            }
        }.padding()
    }
}

//struct AccountBucketToolbar_Previews: PreviewProvider {
//    static var previews: some View {
//        AccountBucketToolbar()
//    }
//}
