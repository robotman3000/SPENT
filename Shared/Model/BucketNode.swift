//
//  BucketNode.swift
//  SPENT
//
//  Created by Eric Nims on 7/3/21.
//

import Foundation

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
