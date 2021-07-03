//
//  PreviewHelper.swift
//  SPENT
//
//  Created by Eric Nims on 7/2/21.
//

import Foundation

extension Transaction {
    private static let preview_payees = ["Sporting Goods", "Online Market", "Online Auctions"]
    private static let preview_memos = ["Spending", "A little something", ""]
    
    static func getRandomTransaction(withID: Int64, withSource: Int64?, withDestination: Int64?, withGroup: UUID?) -> Transaction {
        let date = generateRandomDate(daysBack: 7) ?? Date()
        return Transaction(id: withID,
                           status: .allCases.randomElement() ?? .Void,
                           date: date, posted: date,
                           amount: Int.random(in: 100..<10000),
                           sourceID: withSource,
                           destID: withDestination,
                           memo: preview_memos.randomElement() ?? "",
                           payee: preview_payees.randomElement() ?? "",
                           group: withGroup)
    }
}
