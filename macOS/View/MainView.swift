//
//  MainView.swift
//  macOS
//
//  Created by Eric Nims on 8/26/21.
//

import SwiftUI
import SwiftUIKit

struct MainView: View {
    @State var filter: String = ""
    @State var selectedView: Int64? = -1
    
    var body: some View {
        NavigationView {
            VStack {
                BalanceTable(forID: selectedView).height(202)
                QueryWrapperView(source: BucketTreeFilter()) { bucketIDs in
                    BucketNavigationView(ids: bucketIDs, selection: $selectedView)
                }
            }
            .toolbar(){
                ToolbarItem(placement: .navigation) {
                    Button(action: toggleSidebar, label: {
                        Image(systemName: "sidebar.left")
                    })
                }
            }
            .frame(minWidth: 300, maxWidth: 400)
            .navigationTitle("Accounts")
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

//struct MainView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainView()
//    }
//}
