//
//  BucketNavigation.swift
//  macOS
//
//  Created by Eric Nims on 6/8/21.
//

import SwiftUI

struct BucketNavigation: View, SidebarNavigable {
    
    @EnvironmentObject var stateController: StateController
    @State var selectedBucket: Bucket?
    @Query(BucketRequest()) var buckets: [Bucket]
    @State var bucketTree: [BucketNode] = []
    @State private var showingAlert = false
    @State private var showingForm = false
    
    var body: some View {
        BalanceTable(bucket: $selectedBucket)
        List(selection: $selectedBucket) {
            Section(header: Text("Accounts")){
                OutlineGroup(getBucketTree(treeList: buckets), id: \.bucket, children: \.children) { node in
                    NavigationLink(destination: ListTransactionsView(query: TransactionRequest(node.bucket), title: node.bucket.name)) {
                        BucketRow(bucket: node.bucket)
                    }
                    .contextMenu {
                        Button("Edit") {
                            showingForm.toggle()
                            
                        }
                    }
                }
            }//.collapsible(false)
        }.listStyle(SidebarListStyle())
        .onDeleteCommand {
            do {
                try stateController.database.deleteBucket(id: selectedBucket!.id!)
                selectedBucket = nil
            } catch {
                showingAlert.toggle()
            }
        }
        .sheet(isPresented: $showingForm) {
            BucketForm(title: "Edit Tag", bucket: selectedBucket!, onSubmit: onSubmitBucket, onCancel: {showingForm.toggle()})
            .padding()
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Database Error"),
                message: Text("Failed to delete account"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    func onSubmitBucket(_ bucket: inout Bucket) {
        do {
            try stateController.database.saveBucket(&bucket)
            showingForm.toggle()
        } catch {
            showingAlert.toggle()
        }
    }
    
    func getBucketTree(treeList: [Bucket]) -> [BucketNode] {
        print("Did set")
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
        
        // Now idList contains only the nodes with no children
        idList.subtract(parentIDList)
        print(idList)
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

class BucketNode: Hashable {
    static func == (lhs: BucketNode, rhs: BucketNode) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(index)
        hasher.combine(bucket)
    }
    
    let index: Int
    let bucket: Bucket
    var children: [BucketNode]?
    
    init(index: Int, bucket: Bucket){
        self.index = index
        self.bucket = bucket
    }
}
//struct BucketNavigation_Previews: PreviewProvider {
//    static var previews: some View {
//        BucketNavigation()
//    }
//}
