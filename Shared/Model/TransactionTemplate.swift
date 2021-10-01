//
//  TransactionTemplate.swift
//  macOS
//
//  Created by Eric Nims on 9/16/21.
//

import Foundation
import GRDB

struct TransactionTemplate: Codable, DatabaseValueConvertible {
    var tags: [String]
}
