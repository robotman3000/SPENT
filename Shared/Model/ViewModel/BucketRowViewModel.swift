//
//  BucketRowViewModel.swift
//  SPENT
//
//  Created by Eric Nims on 7/2/21.
//

import Foundation
import SwiftUI

class BucketRowViewModel: ObservableObject, ViewModel {

    @Published var bucket: Bucket
    @Published var balance: BucketBalance
    
    init(withBucket: Bucket){
        print("Model init: \(withBucket.name)")
        bucket = withBucket
        balance = BucketBalance(posted: 0, available: 0, postedInTree: 0, availableInTree: 0)
        //_bal = Query(BucketBalanceRequest(bucket.wrappedValue))
    }
    
    func load(_ db: AppDatabase) {
        balance = BucketBalance(posted: 10, available: 10, postedInTree: 10, availableInTree: 10)
    }
    
    static func previewData() -> BucketRowViewModel {
        let bucket1 = Bucket(id: 5, name: "Another Bucket", parentID: nil, ancestorID: nil, memo: "Some memo", budgetID: nil)
        
        return BucketRowViewModel(withBucket: bucket1)
    }
}
