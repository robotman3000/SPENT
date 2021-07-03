//
//  TransactionRowViewModel.swift
//  SPENT
//
//  Created by Eric Nims on 7/2/21.
//

import Foundation
import SwiftUI

class TransactionRowViewModel: ObservableObject, ViewModel {
    @EnvironmentObject private var store: DatabaseStore
    @Published var transaction: Transaction
    @Published var bucket: Bucket
    @Published var tags: [Tag]?
    
    @Published var sourceName = ""
    @Published var destName = ""
    @Published var direction = Transaction.TransType.Deposit

    init(withTransaction: Transaction, withBucket: Bucket, withTags: [Tag]? = nil){
        self.transaction = withTransaction
        self.bucket = withBucket
        self.tags = withTags
    }
    
    func load(_ db: AppDatabase) {
        //TODO: Make these use value observation to stay updated
        sourceName = store.getBucketByID(transaction.sourceID)?.name ?? ""
        destName = store.getBucketByID(transaction.destID)?.name ?? ""
        direction = transaction.getType(convertTransfer: true, bucket: bucket.id!)
    }
    
    static func previewData(selectedBucket: Bucket, withID: Int64, withSource: Bucket?, withDestination: Bucket?, withGroup: UUID?) -> TransactionRowViewModel {
        let model = TransactionRowViewModel(withTransaction: Transaction.getRandomTransaction(withID: withID, withSource: withSource?.id, withDestination: withDestination?.id, withGroup: withGroup), withBucket: selectedBucket)
        model.sourceName = withSource?.name ?? ""
        model.destName = withDestination?.name ?? ""
        return model
    }
}
