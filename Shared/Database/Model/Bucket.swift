//
//  Bucket.swift
//  SPENT
//
//  Created by Eric Nims on 5/14/21.
//

import Foundation
import GRDB

struct Bucket: Identifiable, Codable, Hashable {
    var id: Int64?
    var name: String
    var parentID: Int64?
    var ancestorID: Int64?
    var memo: String = ""
    var isFavorite: Bool = false
    
    private enum CodingKeys: String, CodingKey {
        case id, name = "Name", parentID = "Parent", ancestorID = "Ancestor", memo = "Memo", isFavorite = "Favorite"
    }
}

extension Bucket {
    static let parent = belongsTo(Bucket.self, using: ForeignKey(["Parent"]))
    var parent: QueryInterfaceRequest<Bucket> {
        request(for: Bucket.parent)
    }
    
    static let ancestor = belongsTo(Bucket.self, key: "Ancestor")
    var ancestor: QueryInterfaceRequest<Bucket> {
        request(for: Bucket.ancestor)
    }
    
    //static let transactions = hasMany(Transaction.self)
    var transactions: QueryInterfaceRequest<Transaction> {
        guard id != nil else {
            return Transaction.none()
        }
        return Transaction.all().ownedByBucket(bucket: id!)
    }
    
    static let children = hasMany(Bucket.self, using: ForeignKey(["Parent"]))
    var children: QueryInterfaceRequest<Bucket> {
        request(for: Bucket.children)
    }
    
    var tree: QueryInterfaceRequest<Bucket> {
        // First use an optimization if we are dealing with an account
        if ancestorID == nil {
            return Bucket.filter(Bucket.Columns.ancestor == id)
        }
        
        var theID: String = "NULL"
        if self.id != nil {
            theID = "\(self.id!)"
        }

        let cte = CommonTableExpression(
            recursive: true,
            named: "cte_Buckets",
            sql: """
                SELECT e.id, e.Name, e.Parent, e.Ancestor, e.Memo, e.Favorite
                FROM Buckets e
                WHERE e.id = \(theID)
                
                UNION ALL
                
                SELECT e.id, e.Name, e.Parent, e.Ancestor, e.Memo, e.Favorite
                FROM Buckets e
                JOIN cte_Buckets c ON c.id = e.Parent
            """
        )
        return cte.all().with(cte).asRequest(of: Bucket.self)
    }
    
    static let balance = hasOne(BucketBalance.self, key: "id")
}


// SQL Database support
extension Bucket: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String = "Buckets"
    
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
    
    // Define database columns from CodingKeys
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let parent = Column(CodingKeys.parentID)
        static let ancestor = Column(CodingKeys.ancestorID)
        static let memo = Column(CodingKeys.memo)
        static let favorite = Column(CodingKeys.isFavorite)
    }
}

extension DerivableRequest where RowDecoder == Bucket {
    func orderByTree() -> Self {
        //SELECT * FROM Buckets Order BY Ancestor ASC, Parent ASC
        let parent = Bucket.Columns.parent
        let ancestor = Bucket.Columns.ancestor
        return order(ancestor.asc, parent.asc)
    }
    
    func filterAccounts() -> Self {
        filter(Bucket.Columns.ancestor == nil)
    }
    
    func filterBuckets() -> Self {
        filter(Bucket.Columns.ancestor != nil)
    }
    
    func filter(ancestor: Int64) -> Self {
        filter(Bucket.Columns.ancestor == ancestor)
    }
    
    func filter(parent: Int64) -> Self {
        filter(Bucket.Columns.parent == parent)
    }
}

// Utility Functions
extension Bucket {
    static func newBucket() -> Bucket {
        return Bucket(id: nil, name: "", parentID: nil, ancestorID: nil, memo: "")
    }
    
    func isAccount() -> Bool {
        return self.ancestorID == nil
    }
}
