//
//  Recipt.swift
//  SPENT
//
//  Created by Eric Nims on 6/17/21.
//

import Foundation
import GRDB

struct Attachment: Identifiable, Codable, Hashable {
    var id: Int64?
    var filename: String
    var sha256: String
}

// SQL Database support
extension Attachment: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "Attachments"
    
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
    
    // Define database columns from CodingKeys
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let filename = Column(CodingKeys.filename)
        static let sha256 = Column(CodingKeys.sha256)
    }
}

//extension Attachment {
//    func showInFinder(url: URL?) {
//        guard let url = url else { return }
//        
//        if url.isDirectory {
//            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
//        }
//        else {
//            showInFinderAndSelectLastComponent(of: url)
//        }
//    }
//
//    fileprivate func showInFinderAndSelectLastComponent(of url: URL) {
//        NSWorkspace.shared.activateFileViewerSelecting([url])
//    }
//}
