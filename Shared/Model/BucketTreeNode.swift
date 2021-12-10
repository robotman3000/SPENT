//
//  BucketTreeNode.swift
//  macOS
//
//  Created by Eric Nims on 11/16/21.
//

import Foundation

struct BucketTreeNode {
    var id: Int64
    var isAccount: Bool
    var children: [BucketTreeNode]? = nil
}
