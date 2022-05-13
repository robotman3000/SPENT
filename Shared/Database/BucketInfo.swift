//
//  BucketInfo.swift
//  macOS
//
//  Created by Eric Nims on 5/13/22.
//

import Foundation
import GRDB

struct BucketInfo: Decodable, FetchableRecord {
    var balance: BucketBalance
    var account: Account
    var bucket: Bucket
    
    private enum CodingKeys: String, CodingKey {
        case balance, account = "Account", bucket = "Bucket"
    }
}

//extension BucketInfo {
//    /// The request for all bucket infos except the buckets that "don't exist" I.E. The buckets without any transactions
//    static func all() -> AdaptedFetchRequest<SQLRequest<BucketInfo>> {
//        let request: SQLRequest<BucketInfo> = """
//            SELECT
//                \(columnsOf: Bucket.self),
//                \(columnsOf: BucketBalance.self),
//                \(columnsOf: Account.self)
//            FROM BucketBalance
//            JOIN Buckets ON ("Buckets".id == BucketID) JOIN Accounts ON ("Accounts".id == AccountID)
//        """
//        return request.adapted { db in
//            let adapters = try splittingRowAdapters(columnCounts: [
//                Bucket.numberOfSelectedColumns(db),
//                BucketBalance.numberOfSelectedColumns(db),
//                Account.numberOfSelectedColumns(db)])
//            return ScopeAdapter([
//                CodingKeys.bucket.stringValue: adapters[0],
//                CodingKeys.balance.stringValue: adapters[1],
//                CodingKeys.account.stringValue: adapters[2]])
//        }
//    }
//
//    /// Fetches all account infos
//    static func fetchAll(_ db: Database) throws -> [BucketInfo] {
//        try all().fetchAll(db)
//    }
//}
