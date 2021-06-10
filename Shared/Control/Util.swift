//
//  Util.swift
//  SPENT
//
//  Created by Eric Nims on 4/15/21.
//

import Foundation
import GRDB

func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
}

func loadData() -> [Transaction]{
    var path: String = getDocumentsDirectory().appendingPathComponent("test.db").absoluteString
    let iCloudDocumentsURL: URL? = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
    if iCloudDocumentsURL != nil {
        path = iCloudDocumentsURL!.appendingPathComponent("test.db").absoluteString
    } else {
        print("Failed to load iCloud DB")
    }
    print(path)
    var transactions: [Transaction] = []
    do {
        let dbQueue = try DatabaseQueue(path: path)
    
        // 2. Define the database schema
        /*try dbQueue.write { db in
            try db.create(table: "Transactions") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("Status", .integer).notNull()
                t.column("TransDate", .date).notNull()
                t.column("PostDate", .date)
                t.column("Amount", .double).notNull()
                t.column("SourceBucket", .integer).notNull()
                t.column("DestBucket", .integer).notNull()
                t.column("Memo", .text)
                t.column("Payee", .text)
            }
        }*/
        // 3. Define a record type

        // 4. Access the database
        /*try dbQueue.write { db in
            try Player(id: 1, name: "Arthur", score: 100).insert(db)
        }*/

        transactions = try dbQueue.read { db in
            try Transaction.fetchAll(db)
        }
        
        print("Transactions:")
        for trans in transactions {
            print(trans)
        }
    } catch {}
    return transactions
    // Start the python interpreter
    //PyBridge.start(path: Bundle.main.resourcePath!, docPath: getDocumentsDirectory().appendingPathComponent("test.db").absoluteString)
    
    //PyBridge.void_call(req: ["function" : "initAPI", "path" : getDocumentsDirectory().appendingPathComponent("test.db").absoluteString])
    
    //let result = PyBridge.call(path: "/database/apirequest", request: APIPacket(action: "get", type: "transaction", data: JSONEncoder().encode()))
    
    //let jsonData = result.records[0].data
    //let parsedData: [String] = try! JSONDecoder().decode([String].self, from: jsonData)
    
    //print(jsonData)
    
    //let jsarr = jsonData.jsonArray
    /*for row in jsarr! {
        theData.transactions.append(TransItem(row.jsonDict!))
    }*/

    // Finalize the python interpreter
    //PyBridge.stop()
    
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

//func toString(_ status: Transaction.StatusTypes?) -> String {
//    if status == nil {
//        return "nil"
//    }
//    return toString(status.rawValue)
//}

//func randomTransactionSet(source: TransactionContainer, destination: TransactionContainer, size: UInt) -> [Transaction]{
//    var tmp: [Transaction] = []
//    for _ in 0..<size {
//        tmp.append(randomTransaction(source: source, destination: destination))
//    }
//    return tmp
//}

//class Tests {
//    static let testData = TestData()
//}
//
//struct TestData {
//    var accounts: [Account]
//    var testAccount: Account
//
//    init(){
//        let acc1 = Account(name: "Test Account 1")
//        let acc2 = Account(name: "Test Account 2")
//        let acc3 = Account(name: "Test Account 3")
        
//        // Random Deposits and Withdrawals
//        randomizeTransactions(container: acc1, count: 10)
//        randomizeTransactions(container: acc2, count: 50)
//        randomizeTransactions(container: acc3, count: 50)
//
//        // Random Transfers
//        let randomTransfers = randomTransactionSet(source: acc3, destination: acc2, size: 5) + randomTransactionSet(source: acc2, destination: acc3, size: 5)
//        acc2.add(randomTransfers)
//        acc3.add(randomTransfers)
//
//        // Test buckets and subbuckets
//        let buk1 = randomizeTransactions(container: Bucket(name: "Bucket A", ancestor: acc2), count: 7) as! Bucket
//        let buk2 = randomizeTransactions(container: Bucket(name: "Bucket B", ancestor: acc2), count: 7) as! Bucket
//
//        let sbuk1 = randomizeTransactions(container: Bucket(name: "SBucket 1", parent: buk1, ancestor: acc2), count: 10) as! Bucket
//        let sbuk2 = randomizeTransactions(container: Bucket(name: "SBucket 2", parent: buk1, ancestor: acc2), count: 10) as! Bucket
//        let sbuk3 = Bucket(name: "SBucket 3", parent: buk1, ancestor: acc2)
//        let sbuk4 = randomizeTransactions(container: Bucket(name: "SBucket 4", parent: buk1, ancestor: acc2), count: 10) as! Bucket
//        buk1.add([sbuk1, sbuk2, sbuk3, sbuk4])
//
//        let sbuk5 = randomizeTransactions(container: Bucket(name: "SBucket 5", parent: buk2, ancestor: acc2), count: 6) as! Bucket
//        let sbuk6 = Bucket(name: "SBucket 6", parent: buk2, ancestor: acc2)
//        buk2.add([sbuk5, sbuk6])
//
//        acc2.add([buk1, buk2])
//
//        accounts = [acc1, acc2, acc3]
//        testAccount = acc2
//    }
//
//}

//func randomizeTransactions(container: TransactionContainer, count: UInt) -> TransactionContainer {
//    container.add(randomTransactionSet(source: container, destination: Account.ROOT, size: count) + randomTransactionSet(source: Account.ROOT, destination: container, size: count))
//    return container
//}

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


