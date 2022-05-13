//
//  AccountRunningBalance.swift
//  macOS
//
//  Created by Eric Nims on 5/13/22.
//

import Foundation
import GRDB

struct AccountRunningBalance: Decodable, FetchableRecord, TableRecord {
    let runningBalance: Int?
    let accountID: Int64
    let transactionID: Int64
}
