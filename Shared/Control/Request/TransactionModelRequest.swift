//
//  File.swift
//  SPENT
//
//  Created by Eric Nims on 7/3/21.
//

import Foundation
import GRDB

struct TransactionModelRequest: Queryable {
    static func == (lhs: TransactionModelRequest, rhs: TransactionModelRequest) -> Bool {
        return lhs.id == rhs.id
    }
    
    static var defaultValue: [TransactionData] { [] }
    
    /// This query is used to filter and sort the transactions after being selected by bucket
    private let filter: TransactionFilter
    private let id: UUID
    
    /// Selects every transaction in the database if includeAll is true
    init(withFilter: TransactionFilter){
        self.filter = withFilter
        self.id = UUID()
    }
    
    func fetchValue(_ db: Database) throws -> [TransactionData] {
        return try filter.getMatches(db)
    }
}
