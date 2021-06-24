//
//  iOSTransactionView.swift
//  iOS
//
//  Created by Eric Nims on 6/24/21.
//

import Foundation
import SwiftUI

struct iOSTransactionView: View {
    @Environment(\.appDatabase) private var database: AppDatabase?
    @EnvironmentObject var store: DatabaseStore
    @ObservedObject var model: TransactionViewModel
    @State var bucket: Bucket?
    
    init(bucket: Bucket) {
        model = TransactionViewModel(query: Transaction.all(), bucket: bucket)
        self.bucket = bucket
    }
    
    var body: some View {
        ListTransactionsView(transactions: model.transactions, bucket: model.contextBucket).onAppear(perform: {
            print("mav view render")
            model.load(database!)
        })
    }
}
