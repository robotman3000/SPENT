//
//  UIDatabaseConnector.swift
//  SPENT
//
//  Created by Eric Nims on 6/19/21.
//

import Foundation
import SwiftUI
import GRDB
import Combine

private func printError(error: Error) {
    print(error)
}

class DatabaseStore: ObservableObject {
    var database: AppDatabase?
    
    @Published var buckets: [Bucket] = [] {
        didSet {
            bucketTree = getBucketTree(treeList: buckets)
        }
    }
    @Published var bucketTree: [BucketNode] = []
    private var bucketIDMap: [Int64:Int] = [:]
    private let bucketObserver: ValueObservation<ValueReducers.Fetch<[Bucket]>>
    private var bucketCancellable: AnyCancellable?
    
    @Published var accounts: [Bucket] = []
    private let accountObserver: ValueObservation<ValueReducers.Fetch<[Bucket]>>
    private var accountCancellable: AnyCancellable?
    
    @Published var tags: [Tag] = []
    private let tagObserver: ValueObservation<ValueReducers.Fetch<[Tag]>>
    private var tagCancellable: AnyCancellable?
    
    @Published var schedules: [Schedule] = []
    private let scheduleObserver: ValueObservation<ValueReducers.Fetch<[Schedule]>>
    private var scheduleCancellable: AnyCancellable?
    
    init(){
        bucketObserver = ValueObservation.tracking(Bucket.fetchAll)
        accountObserver = ValueObservation.tracking(Bucket.all().filterAccounts().fetchAll)
        tagObserver = ValueObservation.tracking(Tag.fetchAll)
        scheduleObserver = ValueObservation.tracking(Schedule.fetchAll)
    }
    
    func preview() -> Self {
        buckets.append(Bucket(id: 1, name: "Demo Account", parentID: nil, ancestorID: nil, memo: "The Demo Memo", budgetID: nil))
        return self
    }
    
    func load(_ db: AppDatabase){
        self.database = db
        
        bucketCancellable = bucketObserver.publisher(in: database!.databaseReader).sink(
            receiveCompletion: {_ in},
            receiveValue: { [weak self] (buckets: [Bucket]) in
                self?.buckets = buckets
            }
        )

        accountCancellable = accountObserver.publisher(in: database!.databaseReader).sink(
            receiveCompletion: {_ in},
            receiveValue: { [weak self] (accounts: [Bucket]) in
                self?.accounts = accounts
            }
        )
        
        tagCancellable = tagObserver.publisher(in: database!.databaseReader).sink(
            receiveCompletion: {_ in},
            receiveValue: { [weak self] (tags: [Tag]) in
                self?.tags = tags
            }
        )
        
        scheduleCancellable = scheduleObserver.publisher(in: database!.databaseReader).sink(
            receiveCompletion: {_ in},
            receiveValue: { [weak self] (schedules: [Schedule]) in
                self?.schedules = schedules
            }
        )
    }
}

// Transactions
extension DatabaseStore {
    func updateTransaction(_ data: inout Transaction, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        print(data)
        do {
            try database!.saveTransaction(&data)
            onComplete()
        } catch {
            onError(error)
        }
    }

    func deleteTransaction(_ id: Int64, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        deleteTransactions([id], onComplete: onComplete, onError: onError)
    }

    func deleteTransactions(_ ids: [Int64], onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        do {
            try database!.deleteTransactions(ids: ids)
            onComplete()
        } catch {
            onError(error)
        }
    }
    
    func getEmptyTransaction() -> Binding<Transaction> {
        return Binding<Transaction>(
            get: {
                Transaction(id: nil, status: .Uninitiated, date: Date(), amount: 0)
            },
            set: { _ in
                print("Trans binding: ignoring set")
            }
        )
    }
    
    func setTransactionTags(transaction: Transaction, tags: [Tag], onComplete: () -> Void = {}, onError: (Error) -> Void = printError) {
        do {
            try database!.setTransactionTags(transaction: transaction, tags: tags)
            onComplete()
        } catch {
            onError(error)
        }
    }
}

// Buckets
extension DatabaseStore {
    func updateBucket(_ data: inout Bucket, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        print(data)
        do {
            try database!.saveBucket(&data)
            onComplete()
        } catch {
            onError(error)
        }
    }

    func deleteBucket(_ id: Int64, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        do {
            try database!.deleteBucket(id: id)
            onComplete()
        } catch {
            onError(error)
        }
    }
    
    func deleteBuckets(_ ids: [Int64], onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        do {
            try database!.deleteBuckets(ids: ids)
            onComplete()
        } catch {
            onError(error)
        }
    }
    
    func getBucketByID(_ id: Int64?) -> Bucket? {
        if id != nil, let ind = bucketIDMap[id!] {
            return buckets.getByIndex(ind)
        }
        return nil
    }
    
    private func getBucketTree(treeList: [Bucket]) -> [BucketNode] {
        print("Calculating bucket tree")
        //TODO: This must be made faster
        var nodes: [BucketNode] = []
        var idMap: [Int64: Int] = [:]
        var accounts: Set<BucketNode> = []
        var parentIDList: Set<Int64> = []
        var idList: Set<Int64> = []
        
        for i in 0..<treeList.count {
            let node = BucketNode(index: i, bucket: treeList[i])
            nodes.insert(node, at: i)
            if node.bucket.parentID != nil {
                parentIDList.insert(node.bucket.parentID!)
            }
            idList.insert(node.bucket.id!)
            idMap[node.bucket.id!] = node.index
        }
        
        self.bucketIDMap = idMap
        
        // Now idList contains only the nodes with no children
        idList.subtract(parentIDList)
        //print(idList)
        while !idList.isEmpty {
            var newList: Set<Int64> = []
            for id in idList.sorted() {
                // Get the node
                let node = nodes[idMap[id]!]
                
                // If the node is not the top of the tree
                if node.bucket.parentID != nil {
                    // Get the parent node
                    let parent = nodes[idMap[node.bucket.parentID!]!]
                    
                    if parent.children == nil {
                        parent.children = []
                    }
                    // Add the child
                    parent.children?.append(node)
                    
                    // Store the parent for the next pass
                    newList.insert(parent.bucket.id!)
                } else {
                    // Store the top level node
                    accounts.insert(node)
                }
            }
            
            // Take a step up the tree and repeat
            idList = newList
        }
        
        return Array(accounts).sorted(by: { a, b in
            a.bucket.name < b.bucket.name
        })
    }
   
}

// Tags
extension DatabaseStore {
    func updateTag(_ data: inout Tag, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        print(data)
        do {
            try database!.saveTag(&data)
            onComplete()
        } catch {
            onError(error)
        }
    }

    func deleteTag(_ id: Int64, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        do {
            try database!.deleteTag(id: id)
            onComplete()
        } catch {
            onError(error)
        }
    }

}

// Schedules
extension DatabaseStore {
    func updateSchedule(_ data: inout Schedule, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        print(data)
        do {
            try database!.saveSchedule(&data)
            onComplete()
        } catch {
            onError(error)
        }
    }

    func deleteSchedule(_ id: Int64, onComplete: () -> Void = {}, onError: (Error) -> Void = printError){
        do {
            try database!.deleteSchedule(id: id)
            onComplete()
        } catch {
            onError(error)
        }
    }
}
