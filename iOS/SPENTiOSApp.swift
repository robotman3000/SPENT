//
//  SPENTApp.swift
//  SPENT
//
//  Created by Eric Nims on 3/30/21.
//

import SwiftUI

@main
struct SPENTiOSApp: App {
    @State var isActive: Bool = false
    @State var database: AppDatabase
    @StateObject var dbStore: DatabaseStore = DatabaseStore()
    
    init() {
        database = AppDatabase(path: getDBURL())
    }
    
    var body: some Scene {
        WindowGroup {
            if isActive {
                MainView().environmentObject(dbStore).environment(\.appDatabase, database)
            } else {
                SplashView(showLoading: true).onAppear(){
                    print("Initializing State Controller")
                    dbStore.load(database)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Change `2.0` to the desired number of seconds.
                        isActive = true
                    }
                }
            }
        }
    }
}

struct MainView: View {
    @EnvironmentObject var store: DatabaseStore
    @Environment(\.editMode) var editMode
    @State var selectedBucket: Bucket?
    @State private var showingAlert = false
    @State private var showingForm = false
    @State private var selectedView: Int? = -1
    
    init(){
        let device = UIDevice.current
        if device.model == "iPad" && device.orientation.isLandscape {
            self.selectedView = 0
        } else {
            self.selectedView = -1
        }
    }
    
    var body: some View {
        NavigationView {
            VStack{
                List(selection: $selectedBucket) {
                    NavigationLink(destination: Text("Summary"), tag: 0, selection: self.$selectedView) {
                        Label("Summary", systemImage: "house")
                    }
                    NavigationLink(destination: Text("Schedule Management")) {
                        Label("Schedules", systemImage: "calendar.badge.clock")
                    }
                    
                    Section(header: Text("Accounts")){
                        OutlineGroup(store.bucketTree, id: \.bucket, children: \.children) { node in
                            ZStack {
                                QueryWrapperView(source: BucketBalanceRequest(node.bucket)) { balance in
                                    BucketRow(name: node.bucket.name, balance: balance.availableInTree)
                                }
                                NavigationLink(destination: iOSTransactionListView(bucket: node.bucket)) {}
                                    .buttonStyle(PlainButtonStyle()).frame(width:0).opacity(0)
                            }
                        }
                    }
                }
            }.listStyle(InsetGroupedListStyle())
            .navigationTitle("Home")
            .toolbar(content: {
                EditButton()
            })
            Text("Summary 3253241")
        }.phoneOnlyStackNavigationView()
    }
}

extension View {
    func phoneOnlyStackNavigationView() -> some View {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return AnyView(self.navigationViewStyle(StackNavigationViewStyle()))
        } else {
            return AnyView(self)
        }
    }
}
