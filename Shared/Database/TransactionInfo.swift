//
//  TransactionInfo.swift
//  macOS
//
//  Created by Eric Nims on 5/13/22.
//

import Foundation
import GRDB

struct TransactionInfo: Decodable, FetchableRecord, Identifiable {
    let id = UUID()
    
    var transaction: Transaction
    var account: Account
    var bucket: Bucket?
    var transfer: Transfer?
    var split: SplitTransaction?
    var runningBalance: AccountRunningBalance?
    var tags: [Tag]
    
    var type: Transaction.TransType {
        if split != nil {
            return .Split
        }
        
        if transfer != nil {
            return .Transfer
        }
        
        if transaction.amount < 0 {
            return .Withdrawal
        }
        
        return .Deposit
    }
    //var transType: TransactionType
    
    private enum CodingKeys: String, CodingKey {
        case transaction, account = "Account", bucket = "Bucket", runningBalance, transfer, split, tags = "Tags"
    }
}
