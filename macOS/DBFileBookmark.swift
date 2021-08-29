//
//  DBFileBookmark.swift
//  macOS
//
//  Created by Eric Nims on 8/28/21.
//

import Foundation

struct DBFileBookmark: Identifiable, Hashable {
    var id: String { shortName }
    
    let shortName: String
    let path: URL
}
