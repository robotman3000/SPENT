//
//  BucketBalance.swift
//  SPENT
//
//  Created by Eric Nims on 9/30/21.
//

import GRDB

struct BucketBalance: Codable, Hashable, FetchableRecord {
    var bucketID: Int64
    var available: Int
    var posted: Int
    
    static var databaseTableName: String = "bucketBalance"
    
    private enum CodingKeys: String, CodingKey {
        case bucketID = "bid", available = "available", posted = "posted"
    }
}
