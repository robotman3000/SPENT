//
//  TransactionRowMode.swift
//  macOS
//
//  Created by Eric Nims on 5/13/22.
//

import Foundation

enum TransactionRowMode: String, Identifiable, CaseIterable, Stringable {
    case compact
    case full
    
    var id: String { self.rawValue }
    
    func getStringName() -> String {
        switch self {
        case .compact: return "Compact"
        case .full: return "Full"
        }
    }
}
