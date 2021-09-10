//
//  GlobalState.swift
//  SPENT
//
//  Created by Eric Nims on 7/8/21.
//

import Foundation

class GlobalState: ObservableObject {
    @Published var includeTree: Bool = true
    @Published var showInTree: Bool = true
    @Published var showTags: Bool = false
    @Published var sorting = TransactionFilter.Ordering.byDate
    @Published var sortDirection = TransactionFilter.OrderDirection.descending
}
