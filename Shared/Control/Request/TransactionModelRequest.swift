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
        var result = try filter.getMatchedIDs(db)
//        var query = try Transaction.filter(ids: ids)
//            .including(all: Transaction.tags.forKey("tags"))
//            .including(optional: Transaction.source.forKey("source"))
//            .including(optional: Transaction.destination.forKey("destination"))
//            .including(all: Transaction.splitMembers.forKey("splitMembers"))
//
//
//        var result = try TransactionData.fetchAll(db, query)
//
        return result
        //print(result[0])
        //return []
    }


}
