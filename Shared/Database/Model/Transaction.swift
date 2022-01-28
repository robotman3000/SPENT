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
