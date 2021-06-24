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
        do {
            database = try AppDatabase(path: getDBURL())
        } catch {
            print(error)
            database = AppDatabase()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if isActive {
                MainView().environmentObject(dbStore).environment(\.appDatabase, database)
            } else {
                SplashView(showLoading: true).onAppear(){
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0) { // Change `2.0` to the desired number of seconds.
                        print("Initializing State Controller")
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
    
    var body: some View {
        //DatabaseManagerView(onCancel: {})
        NavigationView {
            List {
                //Section(header: Text("Accounts")) {
                    OutlineGroup(store.bucketTree, id: \.bucket, children: \.children) { node in
                        ZStack {
                            BucketRow(bucket: node.bucket).onAppear(perform: {
                                print("Row Appeared: \(node.bucket.name)")
                            })
                            NavigationLink(destination: iOSTransactionView(bucket: node.bucket)) {}
                                .buttonStyle(PlainButtonStyle()).frame(width:0).opacity(0)
                        }
                    }
                //}
                
//                Section(header: Text("Settings")) {
//                    Label("Account", systemImage: "person.crop.circle")
//                    Label("Help", systemImage: "person.3")
//                    Label("Logout", systemImage: "applelogo")
//                }
            }.listStyle(InsetGroupedListStyle()).navigationTitle("Accounts")
        }
    }
}

//struct TransactionList: View {
//    @Query(TransactionRequest(true)) var transactions: [Transaction]
//
//    var body: some View {
//        if !transactions.isEmpty {
//            List(transactions){ transaction in
//                TransactionRow(transaction: transaction)
//            }
//        } else {
//            Text("No Transactions Found")
//        }
//    }
//}
