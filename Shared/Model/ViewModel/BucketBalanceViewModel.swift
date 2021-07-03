//
//  BucketBalanceViewModel.swift
//  macOS
//
//  Created by Eric Nims on 6/24/21.
//

import Foundation
import GRDB
import Combine
import SwiftUI

class BucketBalanceViewModel: ObservableObject {
    private var database: AppDatabase?
    @Published var balance: BucketBalance = BucketBalance(posted: 0, available: 0, postedInTree: 0, availableInTree: 0)
    @Published var bucket: Bucket? {
        didSet {
            print("bal model did set")
            self.transactionCancellable?.cancel()
            self.query = BucketBalanceRequest(bucket)
        }
    }
    private var query: BucketBalanceRequest
    private var transactionCancellable: AnyCancellable?

    init(bucket: Bucket?){
        print("Balance model init \(bucket?.name ?? "nil" )")
        self.bucket = bucket
        self.query = BucketBalanceRequest(bucket)
    }
    
    func load(_ db: AppDatabase){
        database = db
        
        transactionCancellable = ValueObservation
            .tracking(query.fetchValue)
            .publisher(in: database!.databaseReader)
            .sink(
                receiveCompletion: {_ in},
                receiveValue: { [weak self] (balance: BucketBalance) in
                    self?.balance = balance
                }
            )
    }
}

