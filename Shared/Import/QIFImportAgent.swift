//
//  QIFImportAgent.swift
//  SPENT
//
//  Created by Eric Nims on 12/16/21.
//
// This import agent has been tested with MoneyWell qif files

import Foundation
import UniformTypeIdentifiers
import GRDB

struct QIFImportAgent: ImportAgent {
    var allowedTypes: [UTType] = []
    func importFromURL(url: URL, database: DatabaseQueue) throws {
        if url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }

            // https://stackoverflow.com/a/62112007
            
            // open the file for reading
            // note: user should be prompted the first time to allow reading from this location
            guard let filePointer:UnsafeMutablePointer<FILE> = fopen(url.path,"r") else {
                preconditionFailure("Could not open file at \(url.absoluteString)")
            }

            // a pointer to a null-terminated, UTF-8 encoded sequence of bytes
            var lineByteArrayPointer: UnsafeMutablePointer<CChar>? = nil

            // the smallest multiple of 16 that will fit the byte array for this line
            var lineCap: Int = 0

            // initial iteration
            var bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)

            defer {
                // remember to close the file when done
                fclose(filePointer)
            }

            while (bytesRead > 0) {
                
                // note: this translates the sequence of bytes to a string using UTF-8 interpretation
                let lineAsString = String.init(cString:lineByteArrayPointer!)
                
                // do whatever you need to do with this single line of text
                // for debugging, can print it
                print(lineAsString)
                
                // updates number of bytes read, for the next iteration
                bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)
            }
            
        } else {
            print("Failed to open file")
        }
    }
}
