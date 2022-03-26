//
//  Transaction.swift
//  SPENT
//
//  Created by Eric Nims on 5/14/21.
//

import Foundation
import GRDB
import SwiftUI

struct Transaction: Identifiable, Codable, Hashable {
    var id: Int64?
    var status: StatusTypes
    var amount: Int
    var payee: String
    var memo: String
    var entryDate: Date
    var postDate: Date?
    var bucketID: Int64?
    var accountID: Int64
}

// SQL Database support
extension Transaction: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "Transactions"
    
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
    
    // Define database columns from CodingKeys
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let status = Column(CodingKeys.status)
        static let amount = Column(CodingKeys.amount)
        static let memo = Column(CodingKeys.memo)
        static let payee = Column(CodingKeys.payee)
        static let entryDate = Column(CodingKeys.entryDate)
        static let postDate = Column(CodingKeys.postDate)
        static let bucket = Column(CodingKeys.bucketID)
        static let account = Column(CodingKeys.accountID)
    }
}
 
// Status Enum
extension Transaction {
    enum StatusTypes: Int, Codable, CaseIterable, Identifiable, Stringable {
        case Void
        case Uninitiated
        case Scheduled
        case Submitted
        case Posting
        case Complete
        case Reconciled
        
        var id: String { self.getStringName() }
        
        func getStringName() -> String {
            switch self {
            case .Void: return "Void"
            case .Uninitiated: return "Uninitiated"
            case .Scheduled: return "Scheduled"
            case .Submitted: return "Submitted"
            case .Posting: return "Posting"
            case .Complete: return "Complete"
            case .Reconciled: return "Reconciled"
            }
        }
        
        static func fromString(string: String) -> StatusTypes? {
            switch string {
            case "Void": return .Void
            case "Uninitiated": return .Uninitiated
            case "Scheduled": return .Scheduled
            case "Submitted": return .Submitted
            case "Posting": return .Posting
            case "Complete": return .Complete
            case "Reconciled": return .Reconciled
            default:
                return nil
            }
        }
        
        func getIconView() -> some View {
            VStack (alignment: .center){
                switch self {
                case .Void:
                    Circle().fill(Color.black).overlay(Text("X").fontWeight(.bold).foregroundColor(.white))
                case .Uninitiated:
                    Circle().fill(Color.black)
                case .Scheduled:
                    Circle().fill(Color.blue)
                case .Submitted:
                    Circle().fill(Color.pink)
                case .Posting:
                    Circle().fill(Color.red)
                    HStack (spacing: 1){
                        Circle().fill(Color.red)
                        Circle().fill(Color.red)
                        
                    }
                case .Complete:
//                    ZStack{
//                        Circle().fill(Color.white)
//                        Circle().stroke(Color.green, lineWidth: 4)
//                    }
                    Circle().fill(Color.green)
                case .Reconciled:
                    Circle().fill(Color.clear)
                }
            }.help(Text(getStringName()))
        }
    }
}

extension Transaction.StatusTypes: DatabaseValueConvertible { }

// Transaction Type Enum
extension Transaction {
    enum TransType: Int, Codable, CaseIterable, Identifiable, Stringable {
        case Invalid
        case Deposit
        case Withdrawal
        case Transfer
        case Split
        case Split_Head
        
        var id: Int { self.rawValue }
        
        var opposite: Self {
            if self == .Transfer || self == .Split_Head || self == .Split {
                return self
            }
            return self == .Deposit ? .Withdrawal : .Deposit
        }
        
        func getStringName() -> String {
            switch self {
            case .Invalid: return "Invalid"
            case .Withdrawal: return "Withdrawal"
            case .Deposit: return "Deposit"
            case .Transfer: return "Transfer"
            case .Split: return "Split Member"
            case .Split_Head: return "Split Head"
            }
        }
    }
}

// Sorting enums
extension Transaction {
    enum Ordering: Int, Identifiable, CaseIterable, Stringable {
        case byEntryDate
        case byPostDate
        case byPayee
        case byMemo
        case byBucket
        case byAccount
        case byStatus
        case byAmount
        
        var id: Int { self.rawValue }
        
        func getStringName() -> String {
            switch self {
            case .byEntryDate: return "Entry Date"
            case .byPostDate: return "Post Date"
            case .byPayee: return "Payee"
            case .byMemo: return "Memo"
            case .byBucket: return "Bucket"
            case .byAccount: return "Account"
            case .byStatus: return "Status"
            case .byAmount: return "Amount"
            }
        }
        
        func getOrdering(_ direction: OrderDirection = .ascending) -> SQLOrdering {
            var column: Column
            switch self {
            case .byEntryDate: column = Transaction.Columns.entryDate
            case .byPostDate: column = Transaction.Columns.postDate
            case .byPayee: column = Transaction.Columns.payee
            case .byMemo: column = Transaction.Columns.memo
            case .byBucket: column = Transaction.Columns.bucket
            case .byAccount: column = Transaction.Columns.account
            case .byStatus: column = Transaction.Columns.status
            case .byAmount: column = Transaction.Columns.amount
            }
            
            switch direction {
            case .ascending:
                return column.asc
            case .descending:
                return column.desc
            }
        }
    }

    enum OrderDirection: String, Identifiable, CaseIterable, Stringable {
        case ascending
        case descending
        
        var id: String { self.rawValue }
        
        func getStringName() -> String {
            switch self {
            case .ascending: return "Ascending"
            case .descending: return "Descending"
            }
        }
    }
}

extension Transaction {
    static let bucket = belongsTo(Bucket.self)
    var bucket: QueryInterfaceRequest<Bucket> {
        request(for: Transaction.bucket)
    }
    
    static let account = belongsTo(Account.self)
    var account: QueryInterfaceRequest<Account> {
        request(for: Transaction.account)
    }
    
    static let tags = hasMany(Tag.self, through: hasMany(TransactionTagMapping.self), using: TransactionTagMapping.tag)
    var tags: QueryInterfaceRequest<Tag> {
        request(for: Transaction.tags)
    }
    
    static let transfer = hasOne(Transfer.self)
    var transfer: QueryInterfaceRequest<Transfer> {
        request(for: Transaction.transfer)
    }
    
    static let split = hasOne(SplitTransaction.self)
    var split: QueryInterfaceRequest<SplitTransaction> {
        request(for: Transaction.split)
    }
    
    //TODO: Running Balance value
}

extension DerivableRequest where RowDecoder == Transaction {
    func filter(account: Account) -> Self {
        filter(Transaction.Columns.account == account.id)
    }
    
    func filter(bucket: Bucket) -> Self {
        filter(Transaction.Columns.bucket == bucket.id)
    }
}
