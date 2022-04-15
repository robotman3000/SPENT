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
    @Published var showCleared: Bool = true
    
    @Published var sorting = Transaction.Ordering.byPostDate
    @Published var sortDirection = Transaction.OrderDirection.descending
    @Published var transRowMode = TransactionRowMode.full
    
    // Not able to be changed during runtime
    var debugMode: Bool = false
}
