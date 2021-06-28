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
    @Published var tags: [Int64 : [Tag]] = [:]
    @Published var query: TransactionRequest
    private(set) var contextBucket: Bucket
    
    private var transactionCancellable: AnyCancellable?
    private var tagCancellable: AnyCancellable?

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
        
        //TODO: This currently fetches and stores all tags. It should be changed to only get the tags for the transactions returned by the TransactionRequest
        tagCancellable = ValueObservation
            .tracking({datab in
                return try TransactionTagLink.fetchAll(datab, Transaction.including(all: Transaction.tags))
            })
            .publisher(in: database!.databaseReader)
            .sink(
                receiveCompletion: {_ in},
                receiveValue: { [weak self] (links: [TransactionTagLink]) in
                    for link in links {
                        self?.tags[link.transaction.id!] = link.TagIDs
                    }
                }
            )
    }
    
    struct TransactionTagLink: FetchableRecord, Decodable {
        var transaction: Transaction
        var TagIDs: [Tag]
    }
}
