//
//  DatabaseRequest.swift
//  macOS
//
//  Created by Eric Nims on 10/20/21.
//

import GRDB
import Foundation

protocol DatabaseRequest {
    associatedtype Value
    
    func requestValue(_ db: Database) throws -> Value
}

struct RequestFetchError: Error, LocalizedError {
    let errorDescription: String?

    init(_ description: String) {
        errorDescription = description
    }
}
