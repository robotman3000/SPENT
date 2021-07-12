//
//  AccountNavigation.swift
//  SPENT
//
//  Created by Eric Nims on 7/8/21.
//

import SwiftUI

struct AccountNavigation: View {
    @EnvironmentObject var store: DatabaseStore
    @Environment(\.editMode) var editMode
    @State private var showingForm = false
    //@State private var selectedView: Int? = -1
    
    init(){
//        let device = UIDevice.current
//        if device.model == "iPad" && device.orientation.isLandscape {
//            self.selectedView = 0
//        } else {
//            self.selectedView = -1
//        }
    }
    
    var body: some View {
        NavigationView {
            List() {
                OutlineGroup(store.bucketTree, id: \.bucket, children: \.children) { node in
                    ZStack {
                        QueryWrapperView(source: BucketBalanceRequest(node.bucket)) { balance in
                            BucketRow(name: node.bucket.name, balance: balance.availableInTree)
                        }
                        NavigationLink(destination: iOSTransactionListView(bucket: node.bucket)) {}
                            .buttonStyle(PlainButtonStyle()).frame(width:0).opacity(0)
                    }
                }.deleteDisabled(false)
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Accounts")
        }//.phoneOnlyStackNavigationView()
    }
}

struct AccountNavigation_Previews: PreviewProvider {
    static var previews: some View {
        AccountNavigation()
    }
}
