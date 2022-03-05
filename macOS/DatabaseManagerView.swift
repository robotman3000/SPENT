//
//  DatabaseManagerView.swift
//  macOS
//
//  Created by Eric Nims on 2/14/22.
//

import Foundation
import SwiftUI

struct DatabaseManagerView: View {
    var body: some View {
        TabView() {
            BucketManagerView().tabItem {
                Label("Buckets", systemImage: "bucket")
                Text("Buckets")
            }
            
            Text("Template Manager").tabItem {
                Label("Templates", systemImage: "paper")
                Text("Templates")
            }
            
            TagManagerView().tabItem {
                Label("Tags", systemImage: "tag")
                Text("Tags")
            }
        }.frame(minWidth: 300, minHeight: 300).padding()
    }
}
