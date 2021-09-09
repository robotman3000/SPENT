//
//  SPENTDatabaseDocument.swift
//  macOS
//
//  Created by Eric Nims on 6/17/21.
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI
import GRDB

extension UTType {
    static var spentDatabase: UTType {
        UTType(exportedAs: "io.github.robotman3000.spent-database")
    }
}

//struct SPENTDatabaseDocument: FileDocument {
//    //private let dbURL: URL
//    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".spentdb")
//    let database: AppDatabase
//    
//    init(){
//        print("Creating a new DB")
//        database = AppDatabase(path: tempURL)
//    }
//
//    init(url: URL){
//        print("Reading Existing DB; Using provided path \(url.absoluteString)")
//        database = AppDatabase(path: url)
//    }
//    
//    init(configuration: ReadConfiguration) throws {
//        print("Reading Existing DB; Using temp path \(tempURL.absoluteString)")
//        database = AppDatabase(configuration.file, tempURL: self.tempURL)
//    }
//
//    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
//        print("Saving DB at \(tempURL.absoluteString)")
//        do {
//            let data = try FileWrapper(url: tempURL.absoluteURL).regularFileContents
//            let fw = FileWrapper(regularFileWithContents: data!)
//            return fw
//        } catch {
//            print(error)
//        }
//        return FileWrapper()
//    }
//    
//    var title = "Enter Title Here"
//
//    static var readableContentTypes: [UTType] { [.spentDatabase] }
//}

// Copied from https://github.com/groue/GRDB.swift/issues/986#issuecomment-860973769
// As a temp solution
extension DatabaseQueue {
    
    /// Copies the contents of the FileWrapper and opens a database at the specified URL.
    ///
    /// The contents of the FileWrapper are copied to the specified location and then opened in-place.
    /// - Parameters:
    ///   - fileWrapper: A regular-file file wrapper.
    ///   - tempFilename: The location to copy the file contents before opening.
    convenience init(fileWrapper: FileWrapper, tempURL: URL) throws {
        // Create a temp database
        try fileWrapper.write(to: tempURL, options: .atomic, originalContentsURL: nil)
        try self.init(path: tempURL.path)
    }
}
