//
//  TransactionViewModel.swift
//  macOS
//
//  Created by Eric Nims on 6/24/21.
//

import Foundation
import GRDB
import Combine
import SwiftUI

class TransactionViewModel: ObservableObject {
    private var database: AppDatabase?
    @Published var transactions: [Transaction] = []
    @Published var query: TransactionRequest
    private(set) var contextBucket: Bucket
    
    private var transactionCancellable: AnyCancellable?

    init(query: QueryInterfaceRequest<Transaction>, bucket: Bucket){
        self.contextBucket = bucket
        self.query = TransactionRequest(bucket, query: query)
    }
    
    func load(_ db: AppDatabase){
        database = db
        
        transactionCancellable = ValueObservation
            .tracking(query.fetchValue)
            .publisher(in: database!.databaseReader)
            .sink(
                receiveCompletion: {_ in},
                receiveValue: { [weak self] (transactions: [Transaction]) in
                    self?.transactions = transactions
                }
            )
    }
}
