//
//  TransactionData.swift
//  SPENT
//
//  Created by Eric Nims on 7/3/21.
//

import Foundation
import GRDB

struct TransactionData: FetchableRecord, Decodable, Hashable {
    var tags: [Tag]
    var source: Bucket?
    var destination: Bucket?
    var transaction: Transaction
}
