//
//  TransactionTemplate.swift
//  macOS
//
//  Created by Eric Nims on 9/16/21.
//

import Foundation
import GRDB

struct TransactionTemplate: Codable, DatabaseValueConvertible {
    var templateVersion: TemplateVersion = .v1
    var name: String
    var memo: String
    var payee: String?
    var amount: Int
    var sourceBucket: Int64?
    var destinationBucket: Int64?
    var tags: [String]
}

extension TransactionTemplate {
    func renderTransaction(date: Date) -> Transaction {
        let transaction = Transaction(id: nil, status: .Uninitiated, date: date, sourcePosted: nil, destPosted: nil, amount: amount, sourceID: sourceBucket, destID: destinationBucket, memo: memo, payee: payee, group: nil, type: .Invalid)
        // TODO: Tags
        
        return transaction
    }
}

enum TemplateVersion: Int, Codable {
    case v1 = 1
}
