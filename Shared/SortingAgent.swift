//
//  SortingAgent.swift
//  SPENT
//
//  Created by Eric Nims on 9/5/21.
//

import SwiftUI
import Foundation

/// The protocol that feeds the `@Query` property wrapper.
protocol SortingAgent: Equatable {
    /// The type of the fetched value
    associatedtype Value
    
    static var defaultValue: [Value] { get }
    
    /// Sorts the provided collection
    func sort(_ input: [Value]) -> [Value]
}

struct TransactionDataSortingAgent: SortingAgent {
    typealias Value = TransactionData
    
    static var defaultValue: [TransactionData] = []
    
    let order: TTransactionFilter.Ordering
    let orderDirection: TTransactionFilter.OrderDirection
    
    func sort(_ input: [TransactionData]) -> [TransactionData] {
        var output: [TransactionData] = input
        
        if order == .byStatus {
            output.sort(by: {
                $0.transaction.status.rawValue < $1.transaction.status.rawValue
            })
        }
        
//        if order == .byAmount {
//            // We sort this in code rather than SQL because all amounts are stored as positive integers
//            output.sort {
//                if $0.transactionType == .Transfer && $1.transactionType == .Transfer {
//                    return $0.transaction.amountNegative < $1.transaction.amountNegative
//                }
//                if $0.transactionType == .Transfer {
//                    return false
//                }
//                if $1.transactionType == .Transfer {
//                    return true
//                }
//
//                return $0.transaction.amountNegative < $1.transaction.amountNegative
//            }
//        }
        
        if orderDirection == .ascending {// && order != .byAmount {
            output = output.reversed()
        }
        return output
    }
}
