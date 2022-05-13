//
//  TransactionType.swift
//  macOS
//
//  Created by Eric Nims on 5/13/22.
//

import Foundation
import GRDB

struct TransactionType: Decodable, FetchableRecord, TableRecord {
    let id: Int64
    let type: String
}
