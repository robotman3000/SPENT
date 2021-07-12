//
//  GlobalState.swift
//  SPENT
//
//  Created by Eric Nims on 7/8/21.
//

import Foundation

class GlobalState: ObservableObject {
    #if os(macOS)
    @Published var selectedView = TransactionViewType.Table
    #endif
    @Published var includeTree: Bool = true
    @Published var sorting = TransactionModelRequest.Ordering.byDate
    @Published var sortDirection = TransactionModelRequest.OrderDirection.descending
    @Published var contextBucket: Bucket?
}
