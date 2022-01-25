//
//  ExportAgent.swift
//  iOS
//
//  Created by Eric Nims on 1/25/22.
//

import Foundation
import UniformTypeIdentifiers

protocol ExportAgent {
    //var communicator: ImportExportCommunicator { get }
    func exportToURL(url: URL, database: DatabaseStore) throws -> Void
}
