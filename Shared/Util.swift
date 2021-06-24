//
//  Util.swift
//  SPENT
//
//  Created by Eric Nims on 4/15/21.
//

import Foundation
import GRDB
import SwiftUI

/// This wraps the struct of Type in an observable class so that we can know when the struct is changed or becomes nil
class ObservableStructWrapper<Type>: ObservableObject {
    @Published var wrappedStruct: Type?
}

func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
}

func getDBURL() -> URL {
    // Pick a folder for storing the SQLite database, as well as
    // the various temporary files created during normal database
    // operations (https://sqlite.org/tempfiles.html).
//    let fileManager = FileManager()
//    let folderURL = try fileManager
//        .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
//        .appendingPathComponent("database", isDirectory: true)
//
//    // Support for tests: delete the database if requested
//    if CommandLine.arguments.contains("-reset") {
//        print("Resetting DB as requested")
//        try? fileManager.removeItem(at: folderURL)
//    }
//
    // Create the database folder if needed
    //try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
    
    // Connect to a database on disk
    // See https://github.com/groue/GRDB.swift/blob/master/README.md#database-connections
    let dbURL = getDocumentsDirectory().appendingPathComponent("db.spentdb")
    
    print("Using DB at: \(dbURL.absoluteString)")
    return dbURL
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

func toString(_ str: String?) -> String {
    if str == nil {
        return "nil"
    }
    return str!
}

func toString(_ int: Int64?) -> String {
    if int == nil {
        return "nil"
    }
    return int!.description
}

func toString(_ int: Int?) -> String {
    if int == nil {
        return "nil"
    }
    return int!.description
}

extension Int {
    var currencyFormat: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: Double(self) / 100.0)) ?? ""
    }
}

extension Date {
    var transactionFormat: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
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

extension Array {
    func getByIndex(_ index: Int) -> Element? {
        if self.count > index {
            return self[index]
        }
        return nil
    }
}

extension Bool {
    mutating func flipFlop() -> Bool {
        self.toggle()
        return self
    }
}
