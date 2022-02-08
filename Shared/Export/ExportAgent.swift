//
//  ExportAgent.swift
//  iOS
//
//  Created by Eric Nims on 1/25/22.
//

import Foundation
import UniformTypeIdentifiers
import GRDB

protocol ExportAgent {
    var allowedTypes: [UTType] { get }
    //var communicator: ImportExportCommunicator { get }
    func exportToURL(url: URL, database: DatabaseQueue) throws -> Void
}
