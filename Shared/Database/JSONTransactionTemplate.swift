//
//  TransactionTemplate.swift
//  macOS
//
//  Created by Eric Nims on 9/16/21.
//

import Foundation
import GRDB

struct JSONTransactionTemplate: Codable, DatabaseValueConvertible {
    var templateVersion: TemplateVersion = .v1
    var name: String
    var memo: String
    var payee: String?
    var amount: Int
    var account: Int64?
    var bucket: Int64?
    var tags: [String]
}

extension JSONTransactionTemplate {
    func renderTransaction(date: Date) -> Transaction {
        let transaction = Transaction(id: nil, status: .Uninitiated, amount: amount, payee: payee ?? "", memo: memo, entryDate: date, postDate: nil, bucketID: bucket, accountID: account ?? -1)
        // TODO: Tags
        
        return transaction
    }
}

enum TemplateVersion: Int, Codable {
    case v1 = 1
}
