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
struct SPENT: App {
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
                MainView().environmentObject(globalState).environmentObject(dbStore).environment(\.appDatabase, dbStore.database!)
            } else {
                SplashView(showLoading: true).frame(minWidth: 1000, minHeight: 600).onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now()) {
                        print("Initializing State Controller")
                        print("Source Version: \(Bundle.main.object(forInfoDictionaryKey: "GIT_COMMIT_HASH") ?? "(NIL)")")
                        print("App Name: \(Bundle.main.object(forInfoDictionaryKey: "CFBundleName") ?? "(NIL)")")
                        print("Identifier: \(Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") ?? "(NIL)")")
                        loadDBBookmark()
                    }
                }
                .sheet(isPresented: $showWelcomeSheet, content: {
                    WelcomeSheet(showWelcomeSheet: $showWelcomeSheet, loadDatabase: {url in
                         let database = AppDatabase(path: url)
                         dbStore.load(database)
                        isActive.toggle()
                    })
                })
            }
        }.commands {
            CommandGroup(replacing: .newItem){
                Button("New Window"){
                    WindowKeys.MainWindow.open()
                }
            }
            CommandGroup(after: .newItem) {
                Section{
                    Button("New Account") {
                        context.present(FormKeys.account(context: context, account: nil, onSubmit: {data in
                            dbStore.updateBucket(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                        }))
                    }
                }
                
                Button("Change Database") {
                    isDBSwitch = true
                    isActive.toggle()
                    showWelcomeSheet = true
                }
            }
            
            CommandGroup(after: .appSettings){
                Button("Manage Tags"){
                    WindowKeys.TagManager.open()
                }
                
                Button("Manage Schedules"){
                    WindowKeys.ScheduleManager.open()
                }
            }
            
            CommandGroup(replacing: .importExport) {
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
                        aContext.present(AlertKeys.notImplemented)
                    }
                }
                
                Menu("Export As") {
                    Button("CSV File") {
                        aContext.present(AlertKeys.notImplemented)
                    }
                }
            }
        }
        
        WindowGroup("Tag Manager") {
            TagManagerView().environmentObject(globalState).environmentObject(dbStore)
        }.handlesExternalEvents(matching: Set(arrayLiteral: WindowKeys.TagManager.rawValue))
        
        WindowGroup("Schedule Manager") {
            ScheduleManagerView().environmentObject(globalState).environmentObject(dbStore)
        }.handlesExternalEvents(matching: Set(arrayLiteral: WindowKeys.ScheduleManager.rawValue))
        
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
