//
//  TransactionTagLink.swift
//  SPENT
//
//  Created by Eric Nims on 6/29/21.
//

import Foundation
import GRDB

struct TransactionTagLink: FetchableRecord, Decodable {
    var transaction: Transaction
    var TagIDs: [Tag]
}
