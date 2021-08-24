//
//  GlobalState.swift
//  SPENT
//
//  Created by Eric Nims on 7/8/21.
//

import Foundation

class GlobalState: ObservableObject {
    @Published var includeTree: Bool = true
    @Published var showTags: Bool = false
    @Published var sorting = TransactionModelRequest.Ordering.byDate
    @Published var sortDirection = TransactionModelRequest.OrderDirection.descending
    @Published var contextBucket: Bucket?
}
