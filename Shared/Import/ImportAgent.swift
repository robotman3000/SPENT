//
//  ImportAgent.swift
//  macOS
//
//  Created by Eric Nims on 8/24/21.
//

import Foundation
import UniformTypeIdentifiers
import GRDB

protocol ImportAgent {
    //var communicator: ImportExportCommunicator { get }
    var allowedTypes: [UTType] { get }
    var displayName: String { get }
    func importFromURL(url: URL, database: DatabaseQueue) throws -> Void
}
