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

func generateRandomDate(daysBack: Int)-> Date? {
    let day = arc4random_uniform(UInt32(daysBack))+1
    let hour = arc4random_uniform(23)
    let minute = arc4random_uniform(59)
    
    let today = Date(timeIntervalSinceNow: 0)
    let gregorian  = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)
    var offsetComponents = DateComponents()
    offsetComponents.day = -1 * Int(day - 1)
    offsetComponents.hour = -1 * Int(hour)
    offsetComponents.minute = -1 * Int(minute)
    
    let randomDate = gregorian?.date(byAdding: offsetComponents, to: today, options: .init(rawValue: 0) )
    return randomDate
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
