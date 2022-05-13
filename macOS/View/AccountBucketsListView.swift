//
//  AccountBucketsListView.swift
//  macOS
//
//  Created by Eric Nims on 5/13/22.
//

import SwiftUI
import SwiftUIKit
import GRDBQuery

struct AccountBucketsListView: View {
    @StateObject var sheetContext = SheetContext()
    @StateObject var alertContext = AlertContext()
    @Query<AccountBuckets> var buckets: [BucketInfo]
    let account: Account
    @State var selection: Bucket? = nil as Bucket?
    
    init(forAccount: Account){
        self._buckets = Query(AccountBuckets(forAccount: forAccount), in: \.dbQueue)
        self.account = forAccount
    }
    
    var body: some View {
        List {
            NavigationLink(destination: AccountTransactionsView(forAccount: account, withBucket: nil)){
                Text("All Transactions")
            }
            Divider()
            ForEachEnumerated(buckets.sorted(by: { a, b in a.bucket.category < b.bucket.category })){ bucketInfo in
                NavigationLink(destination: AccountTransactionsView(forAccount: account, withBucket: selection), tag: bucketInfo.bucket, selection: $selection){
                    BucketListRow(forBucket: bucketInfo)
                }.contextMenu { BucketContextMenu(sheet: sheetContext, alertContext: alertContext, forBucket: bucketInfo.bucket) }
            }
            
            if buckets.isEmpty {
                Text("No Buckets")
            }
        }.sheet(context: sheetContext)
        .alert(context: alertContext)
        .contextMenu {
            Button("New Bucket"){
                sheetContext.present(FormKeys.bucket(context: sheetContext, bucket: nil))
            }
        }
    }
}

//struct AccountBucketsListView_Previews: PreviewProvider {
//    static var previews: some View {
//        AccountBucketsListView()
//    }
//}
