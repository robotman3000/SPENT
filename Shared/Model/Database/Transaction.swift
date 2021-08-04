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
    var date: Date
    var posted: Date?
    var amount: Int
    var sourceID: Int64?
    var destID: Int64?
    var memo: String = ""
    var payee: String?
    
    static let databaseUUIDEncodingStrategy = DatabaseUUIDEncodingStrategy.string
    var group: UUID?
    
    var type: TransType {
        get {
            if sourceID == nil && destID == nil {
                return .Split
            }
            
            if sourceID != nil {
                if destID != nil {
                    return .Transfer
                } else {
                    return .Withdrawal
                }
            }
            return .Deposit
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, status = "Status", date = "TransDate", posted = "PostDate", amount = "Amount", sourceID = "SourceBucket", destID = "DestBucket", memo = "Memo", payee = "Payee", group = "Group"
    }
    
//    var amount: Double {
//        get { Decimal(raw_amount) / 100 }
//        set { raw_amount = newValue * 100.00 }
//    }
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
        static let transdate = Column(CodingKeys.date)
        static let postdate = Column(CodingKeys.posted)
        static let amount = Column(CodingKeys.amount)
        static let sourcebucket = Column(CodingKeys.sourceID)
        static let destbucket = Column(CodingKeys.destID)
        static let memo = Column(CodingKeys.memo)
        static let payee = Column(CodingKeys.payee)
        static let group = Column(CodingKeys.group)
    }
}

extension Transaction {
    static let source = belongsTo(Bucket.self, using: ForeignKey(["SourceBucket"]))
    var source: QueryInterfaceRequest<Bucket> {
        request(for: Transaction.source)
    }
    
    static let destination = belongsTo(Bucket.self, using: ForeignKey(["DestBucket"]))
    var destination: QueryInterfaceRequest<Bucket> {
        request(for: Transaction.destination)
    }
    
    static let tags = hasMany(Tag.self, through: hasMany(TransactionTag.self, key: "TransactionID"), using: TransactionTag.tag)
    var tags: QueryInterfaceRequest<Tag> {
        request(for: Transaction.tags)
    }
    
    static let splitMembers = hasMany(Transaction.self, using: ForeignKey(["Group"], to: ["Group"]))
    var splitMembers: QueryInterfaceRequest<Transaction> {
        request(for: Transaction.splitMembers)
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
        
        func getIconView() -> some View {
            VStack (alignment: .center){
                switch self {
                case .Void:
                    Circle().fill(Color.white).overlay(Circle().stroke(Color.black, lineWidth: 4))
                case .Uninitiated:
                    Circle().fill(Color.black)
                case .Scheduled:
                    Circle().fill(Color.blue)
                case .Submitted:
                    Circle().fill(Color.pink)
                case .Posting:
                    Circle().fill(Color.red)
                case .Complete:
                    ZStack{
                        Circle().fill(Color.white)
                        Circle().stroke(Color.green, lineWidth: 4)
                        
                    }
                case .Reconciled:
                    Circle().fill(Color.green)
                }
            }.help(Text(getStringName()))
        }
    }
}


extension Transaction.StatusTypes: DatabaseValueConvertible { }

// Transaction Type Enum
extension Transaction {
    enum TransType: String, Codable, CaseIterable, Identifiable, Stringable {
        case Deposit
        case Withdrawal
        case Transfer
        case Split
        
        var id: String { self.rawValue }
        
        var opposite: Self {
            if self == .Transfer || self == .Split {
                return self
            }
            return self == .Deposit ? .Withdrawal : .Deposit
        }
        
        func getStringName() -> String {
            return self.rawValue
        }
    }
    
    func getType(convertTransfer: Bool = false, bucket: Int64?) -> Transaction.TransType {
        if sourceID == nil && destID == nil {
            return .Split
        }
        
        if sourceID != nil && destID != nil && convertTransfer && bucket != nil {
            if sourceID == bucket {
                return .Withdrawal
            }
            return .Deposit
        }
        return type
    }
}

// Random transaction generation for testing
extension Transaction {
    static func newRandom(id: Int64, bucketIDs: [Int64]) -> Transaction {
        return Transaction(id: id,
                           status: Transaction.StatusTypes.allCases[Int.random(in: 0..<Transaction.StatusTypes.allCases.count)],
                           date: generateRandomDate(daysBack: 5)!,
                           posted: generateRandomDate(daysBack: 5),
                           amount: Int.random(in: 0..<10000),
                           sourceID: bucketIDs.randomElement()!,
                           destID: bucketIDs.randomElement()!,
                           memo: "Test Memo \(Int.random(in: 0..<10))",
                           payee: ["Person A", "Person B", "Person C"].randomElement())
    }
}

extension DerivableRequest where RowDecoder == Transaction {
    func ownedByBucket(bucket: Int64) -> Self {
        filter(sql: "SourceBucket == ? OR DestBucket == ?", arguments: [bucket, bucket])
    }
    
    func withTag(tag: Int64) -> Self {
        filter(sql: "id in (SELECT TransactionID from TransactionTags WHERE TagID == ?)", arguments: [tag])
    }
    
    func orderedByDate() -> Self {
        order(Transaction.Columns.transdate.desc)
    }
    
    func orderedByPayee() -> Self {
        order(Transaction.Columns.payee.desc)
    }
    
    func orderedByMemo() -> Self {
        order(Transaction.Columns.memo.desc)
    }
    
    func orderedBySource() -> Self {
        order(Transaction.Columns.sourcebucket.desc)
    }
    
    func orderedByDestination() -> Self {
        order(Transaction.Columns.destbucket.desc)
    }
    
    func orderedByStatus() -> Self {
        order(Transaction.Columns.status.desc)
    }
}

// Utility Functions
extension Transaction {
    static func newTransaction() -> Transaction {
        return Transaction(id: nil, status: .Void, date: Date(), posted: nil, amount: 0, sourceID: nil, destID: nil, memo: "", payee: nil, group: nil)
    }
    
    static func newSplitTransaction() -> Transaction {
        return Transaction(id: nil, status: .Void, date: Date(), posted: nil, amount: 0, sourceID: nil, destID: nil, memo: "", payee: nil, group: UUID())
    }
    
    static func newSplitMember(head: Transaction) -> Transaction {
        return Transaction(id: nil, status: head.status, date: head.date, posted: nil, amount: 0, sourceID: nil, destID: nil, memo: "", payee: nil, group: head.group)
    }
    
    static func getSplitDirection(members: [Transaction]) -> TransType {
        // TODO: look into a more efficent process
        
        var sources = Set<Int64?>()
        var dests = Set<Int64?>()
        
        for member in members {
            sources.insert(member.sourceID)
            dests.insert(member.destID)
        }
        
        return dests.count >= sources.count ? .Deposit : .Withdrawal
    }
    
    static func amountSum(_ data: [Transaction]) -> Int {
        //TODO: This function needs to handle deposites and withdrawals correctly
        var amount = 0
        
        for t in data {
            amount += t.amount
        }
        
        return amount
    }
    
    static func getSplitMember(_ data: [Transaction], bucket: Bucket) -> Transaction? {
        for t in data {
            // Eliminate the optional value
            if let bID = bucket.id {
                // and thereby cause nil sources or dests to be ignored
                if t.sourceID == bID || t.destID == bID {
                    return t
                }
            }
        }
        return nil
    }
}
