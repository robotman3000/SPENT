//
//  MacSidebar.swift
//  macOS
//
//  Created by Eric Nims on 6/8/21.
//

import SwiftUI

struct MacSidebar: View {
    
    var body: some View {
        BucketNavigation().onAppear(perform: {print("Sidebar appear")})
            .toolbar(){
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar, label: {
                    Image(systemName: "sidebar.left")
                })
            }
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
