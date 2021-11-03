//
//  DatabaseFilter.swift
//  macOS
//
//  Created by Eric Nims on 10/20/21.
//

import GRDB
import Combine

protocol DatabaseFilter {
    associatedtype Request: DatabaseRequest
    
    static func publisher(_ withReader: DatabaseReader, forID: Int64) -> AnyPublisher<Request.Value, Error>
}
