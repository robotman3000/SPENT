//
//  MacSidebar.swift
//  macOS
//
//  Created by Eric Nims on 6/8/21.
//

import SwiftUI

struct MacSidebar: View {
    @State var selectedType = SidebarListOptions.bucket
    
    var body: some View {
        Picker("Type", selection: $selectedType) {
            ForEach(SidebarListOptions.allCases) { type in
                Text(type.name).tag(type)
            }
        }.padding()
        .toolbar(){
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar, label: {
                    Image(systemName: "sidebar.left")
                })
            }
        }
        switch selectedType {
        case .bucket: BucketNavigation()
        case .tag: TagNavigation()
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}


struct MacSidebar_Previews: PreviewProvider {
    static var previews: some View {
        MacSidebar()
    }
}
