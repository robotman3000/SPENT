//
//  ImportAgent.swift
//  macOS
//
//  Created by Eric Nims on 8/24/21.
//

import Foundation
import UniformTypeIdentifiers

protocol ImportAgent {
    //var communicator: ImportExportCommunicator { get }
    var allowedTypes: [UTType] { get }
    func importFromURL(url: URL, database: DatabaseStore) throws -> Void
}
