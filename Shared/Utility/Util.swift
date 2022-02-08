//
//  Util.swift
//  SPENT
//
//  Created by Eric Nims on 4/15/21.
//

import Foundation
import GRDB
import SwiftUI
import UniformTypeIdentifiers

func openFile(allowedTypes: [UTType], onConfirm: (URL) -> Void, onCancel: () -> Void){
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.allowedContentTypes = allowedTypes
    
    if panel.runModal() == .OK {
        if let selectedFile = panel.url?.absoluteURL {
            onConfirm(selectedFile)
        }
    } else {
        onCancel()
    }
}

func saveFile(allowedTypes: [UTType], onConfirm: (URL) -> Void, onCancel: () -> Void){
    let panel = NSSavePanel()
    panel.allowedContentTypes = allowedTypes
    
    if panel.runModal() == .OK {
        if let selectedFile = panel.url?.absoluteURL {
            onConfirm(selectedFile)
        }
    } else {
        onCancel()
    }
}

func chooseFolder(onConfirm: (URL) -> Void, onCancel: () -> Void){
    let panel = NSOpenPanel()
    panel.canCreateDirectories = true
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    
    if panel.runModal() == .OK {
        if let selectedFolder = panel.url?.absoluteURL {
            onConfirm(selectedFolder)
        }
    } else {
        onCancel()
    }
}

func getURLByBookmark(_ data: Data, isStale: inout Bool) -> URL? {
    do {
        return try URL(resolvingBookmarkData: data,
                  options: URL.BookmarkResolutionOptions.withSecurityScope,
                  relativeTo: nil, bookmarkDataIsStale: &isStale)
    } catch {
        print(error)
    }
    return nil
}

public func genHash(_ items: [AnyHashable]) -> Int{
    var hasher = Hasher()
    for i in items {
        hasher.combine(i)
    }
    return hasher.finalize()
}

let nformatter = NumberFormatter()
extension Int {
    var currencyFormat: String {
        nformatter.numberStyle = .currency
        return nformatter.string(from: NSNumber(value: Double(self) / 100.0)) ?? ""
    }
}

let dformatter = DateFormatter()
extension Date {
    var transactionFormat: String {
        dformatter.dateStyle = .medium
        return dformatter.string(from: self)
    }
}

extension String {
  /*
   Truncates the string to the specified length number of characters and appends an optional trailing string if longer.
   - Parameter length: Desired maximum lengths of a string
   - Parameter trailing: A 'String' that will be appended after the truncation.
    
   - Returns: 'String' object.
  */
  func trunc(length: Int, trailing: String = "…") -> String {
    return (self.count > length) ? self.prefix(length) + trailing : self
  }
}

// https://stackoverflow.com/a/38788437
import Foundation
import CommonCrypto

extension Data{
    public func sha256() -> String{
        return hexStringFromData(input: digest(input: self as NSData))
    }
    
    private func digest(input : NSData) -> NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }
    
    private  func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)
        
        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt8(byte))
        }
        
        return hexString
    }
}

public extension String {
    func sha256() -> String{
        if let stringData = self.data(using: String.Encoding.utf8) {
            return stringData.sha256()
        }
        return ""
    }
}
