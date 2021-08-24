//
//  macOSApp.swift
//  macOS
//
//  Created by Eric Nims on 4/14/21.
//

import SwiftUI
import SwiftUIKit
import GRDB
import Foundation

@main
struct SPENTmacOS: App {
    @State var isActive: Bool = false
    @State var showWelcomeSheet: Bool = false
    @State var isDBSwitch: Bool = false
    @StateObject var globalState: GlobalState = GlobalState()
    @StateObject var dbStore: DatabaseStore = DatabaseStore()
    @StateObject var context: SheetContext = SheetContext()
    @StateObject var aContext: AlertContext = AlertContext()
    
    var body: some Scene {
        WindowGroup {
            if isActive {
                NavigationView {
                    MacSidebar(bucketTree: $dbStore.bucketTree, schedules: dbStore.schedules, tags: dbStore.tags)
                        .frame(minWidth: 300)
                        .navigationTitle("Accounts")
                }
                .environmentObject(globalState)
                .environmentObject(dbStore)
                .environment(\.appDatabase, dbStore.database!)
                .sheet(context: context)
                .alert(context: aContext)
            } else {
                SplashView(showLoading: true).frame(minWidth: 1000, minHeight: 600).onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now()) {
                        print("Initializing State Controller")
                        print("Source Version: \(Bundle.main.object(forInfoDictionaryKey: "GIT_COMMIT_HASH") ?? "(NIL)")")
                        loadDBBookmark()
                    }
                }
                .sheet(isPresented: $showWelcomeSheet, content: {
                    WelcomeSheet(showWelcomeSheet: $showWelcomeSheet, loadDatabase: {url in
                         let database = AppDatabase(path: url)
                         dbStore.load(database)
                         isActive = true
                    })
                })
            }
        }.commands {
            CommandGroup(after: .newItem) {
                Section{
                    Button("New Account") {
                        context.present(UIForms.account(context: context, account: nil, onSubmit: {data in
                            dbStore.updateBucket(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(UIAlerts.databaseError(message: error.localizedDescription ))})
                        }))
                    }
                }
                
                Button("Change Database") {
                    isDBSwitch = true
                    isActive = false
                }
                
                Section{
                    Menu("Import") {
                        Button("SPENT Dev Legacy") {
                            DispatchQueue.main.async {
                                // allowedTypes = SPENTLegacyImportAgent.importTypes
                                openFile(allowedTypes: [], onConfirm: { selectedFile in
                                    if selectedFile.startAccessingSecurityScopedResource() {
                                        SPENTLegacyImportAgent.importSPENTLegacy(url: selectedFile, dbStore: dbStore)
                                    }
                                }, onCancel: {})
                            }
                        }
                        Button("CSV File") {
                            aContext.present(UIAlerts.notImplemented)
                        }
                    }
                    
                    Menu("Export As") {
                        Button("CSV File") {
                            aContext.present(UIAlerts.notImplemented)
                        }
                    }
                }
            }
        }
        
        Settings{
            SettingsView().environmentObject(globalState).environmentObject(dbStore).environment(\.appDatabase, dbStore.database)
        }
    }
    
    func loadDBBookmark(){
        if !isDBSwitch && UserDefaults.standard.bool(forKey: PreferenceKeys.autoloadDB.rawValue) {
            if let dbBookmark = UserDefaults.standard.data(forKey: PreferenceKeys.databaseBookmark.rawValue) {
                var isStale = false
                if let dbURL = getURLByBookmark(dbBookmark, isStale: &isStale) {
                    if dbURL.startAccessingSecurityScopedResource() {
                        defer { dbURL.stopAccessingSecurityScopedResource() }
                        let database = AppDatabase(path: dbURL)
                        dbStore.load(database)
                        isActive = true
                    } else {
                        print("Security failed")
                    }
                } else {
                    print("Bookmark -> URL failed")
                }
            } else {
                print("Bookmark Failed")
            }
        }
        
        if !isActive {
            // Something went wrong opening the prefered db
            showWelcomeSheet.toggle()
        }
    }
}

enum PreferenceKeys: String {
    case autoloadDB
    case databaseBookmark
}
