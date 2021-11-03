//
//  GlobalState.swift
//  SPENT
//
//  Created by Eric Nims on 7/8/21.
//

import Foundation
import SwiftUIKit

class GlobalState: ObservableObject {
    @Published var includeTree: Bool = true
    @Published var showInTree: Bool = true
    @Published var showTags: Bool = false
    @Published var showMemo: Bool = false
    @Published var sorting = TTransactionFilter.Ordering.byDate
    @Published var sortDirection = TTransactionFilter.OrderDirection.descending
    
    // Not able to be changed during runtime
    var debugMode: Bool = false
}
