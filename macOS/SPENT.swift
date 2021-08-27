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
                        print("Source Version: \(Bundle.main.object(forInfoDictionaryKey: "GIT_COMMIT_HASH") as? String ?? "(NIL)")")
                        print("App Name: \(Bundle.main.object(forInfoDictionaryKey: "CFBundleName") ?? "(NIL)")")
                        print("Identifier: \(Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") ?? "(NIL)")")
                        
                        if let dbURL = loadDBBookmark() {
                            setupDBInstance(url: dbURL)
                        }
                        
                        if !isActive {
                            // Something went wrong opening the prefered db
                            showWelcomeSheet.toggle()
                        }
                    }
                }
                .sheet(isPresented: $showWelcomeSheet, content: {
                    WelcomeSheet(showWelcomeSheet: $showWelcomeSheet, loadDatabase: {url,isNew  in
                        setupDBInstance(url: url, skipHashCheck: isNew)
                    })
                }).sheet(context: context)
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
    
    func loadDBBookmark() -> URL? {
        if !isDBSwitch && UserDefaults.standard.bool(forKey: PreferenceKeys.autoloadDB.rawValue) {
            if let dbBookmark = UserDefaults.standard.data(forKey: PreferenceKeys.databaseBookmark.rawValue) {
                var isStale = false
                if let dbURL = getURLByBookmark(dbBookmark, isStale: &isStale) {
                    return dbURL
                } else {
                    print("Bookmark -> URL failed")
                }
            } else {
                print("Bookmark Failed")
            }
        }
        return nil
    }
    
    func loadDB(url: URL) -> AppDatabase? {
        if url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }
            let database = AppDatabase(path: url)
            
            return database
        } else {
            print("Security failed")
        }
        return nil
    }
    
    func setupDBInstance(url: URL, skipHashCheck: Bool = false){
        if let appDB = loadDB(url: url) {
            if checkDBCommit(database: appDB) {
                dbStore.load(appDB)
                isActive = true
            } else {
                let gitCommit: String = Bundle.main.object(forInfoDictionaryKey: "GIT_COMMIT_HASH") as? String ?? "(NIL)"
                
                if !skipHashCheck {
                    let upgradeMessage = "The current git hash is \(gitCommit), the hash in the database doesn't match. Load Anyway?"
                    context.present(FormKeys.confirmAction(context: context, message: upgradeMessage, onConfirm: {
                        setDBCommit(database: appDB, commit: gitCommit)
                        dbStore.load(appDB)
                        isActive = true
                    }, onCancel: {
                        isActive = false
                        showWelcomeSheet = true
                    }))
                } else {
                    // Assume the answer was yes
                    setDBCommit(database: appDB, commit: gitCommit)
                    dbStore.load(appDB)
                    isActive = true
                }
            }
        }
    }
    
    func checkDBCommit(database: AppDatabase) -> Bool {
        do {
            // Check the saved commit hash against ours before handing the raw db to the db store
            let config = try database.databaseReader.read { db in
                try AppConfiguration.fetch(db)
            }
            print("DB Version: \(AppDatabase.DB_VERSION), Loaded Version: \(config.dbVersion)")
            if config.commitHash == Bundle.main.object(forInfoDictionaryKey: "GIT_COMMIT_HASH") as? String ?? "1234567890" {
                print("Hash matched")
                return true
            }
        } catch {
            print(error)
        }
        print("Hash didn't match")
        return false
    }
    
    func setDBCommit(database: AppDatabase, commit: String){
        do {
            try database.getWriter().write { db in
                var config = try AppConfiguration.fetch(db)
                
                // Update some config values
                try config.updateChanges(db) {
                    $0.commitHash = commit
                    $0.dbVersion = AppDatabase.DB_VERSION
                }
            }
        } catch {
            print("Failed to update database commit hash")
            print(error)
        }
    }
}
