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
    @StateObject var globalState: GlobalState = GlobalState()
    
    init() {
        database = AppDatabase(path: getDBURL())
    }
    
    var body: some Scene {
        WindowGroup {
            if isActive {
                MainView().environmentObject(globalState).environmentObject(dbStore).environment(\.appDatabase, database)
            } else {
                SplashView(showLoading: true).onAppear(){
                    print("Initializing State Controller")
                    DispatchQueue.main.asyncAfter(deadline: .now()) { // Change `2.0` to the desired number of seconds.
                        let dbPath = getDBURL()
                        if !FileManager.default.fileExists(atPath: dbPath.path) {
                            do {
                                try FileManager.default.createDirectory(atPath: dbPath.path, withIntermediateDirectories: true, attributes: nil)
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                        
                        let database = AppDatabase(path: dbPath)
                        dbStore.load(database)
                        isActive = true
                    }
                }
            }
        }
    }
}

struct MainView: View {
    @EnvironmentObject var store: DatabaseStore
    @State var selectedBuckets: Set<Bucket> = Set()
    @State private var showingForm = false
    @State private var selectedView: Int? = -1
    @State var editMode: EditMode = .inactive
    
    init(){
        let device = UIDevice.current
        if device.model == "iPad" && device.orientation.isLandscape {
            self.selectedView = 0
        } else {
            self.selectedView = -1
        }
    }
    
    private var editButton: some View {
            Button(action: {
                self.editMode.toggle()
                self.selectedBuckets = Set<Bucket>()
            }) {
                Text(self.editMode.title)
            }
        }
    
    var body: some View {
        NavigationView {
            VStack{
                List(selection: $selectedBuckets) {
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
                }.environment(\.editMode, self.$editMode)
                if editMode == .active {
                    HStack(alignment: .top){
                        Button("Delete Selected"){
                            store.deleteBuckets(Array(selectedBuckets.map({bucket in bucket.id!})), onComplete: {
                                print("done")
                            }, onError: {error in print(error)})
                        }.disabled(selectedBuckets.isEmpty)
                    }.frame(height: 30)
                }
            }.listStyle(InsetGroupedListStyle())
            .sheet(isPresented: $showingForm){
                BucketForm(onSubmit: {data in
                    store.updateBucket(&data, onComplete: dismissModal)
                }, onCancel: dismissModal)
            }
            .navigationTitle("Home")
            .toolbar(content: {
                ToolbarItem(placement: .primaryAction){
                    editButton
                }
                ToolbarItem(placement: .navigationBarLeading){
                    if editMode == .active {
                        Button("New Account"){
                            showingForm.toggle()
                            editMode.toggle()
                        }
                    }
                }
            })
            Text("Summary 3253241")
        }.phoneOnlyStackNavigationView()
    }
    
    func dismissModal(){
        showingForm = false
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

extension EditMode {
    var title: String {
        self == .active ? "Done" : "Edit"
    }

    mutating func toggle() {
        self = self == .active ? .inactive : .active
    }
}
