//
//  GlobalState.swift
//  SPENT
//
//  Created by Eric Nims on 7/8/21.
//

import Foundation
import SwiftUIKit
import GRDB

class GlobalState: ObservableObject {
    @Published var showTags: Bool = false
    @Published var showMemo: Bool = false
    
    @Published var showAllocations: Bool = true
    
//    @Published var sorting = TransactionFilter.Ordering.byDate
//    @Published var sortDirection = TransactionFilter.OrderDirection.descending
    
    // Not able to be changed during runtime
    var debugMode: Bool = false
}
