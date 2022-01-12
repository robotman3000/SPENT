//
//  macOSApp.swift
//  macOS
//
//  Created by Eric Nims on 4/14/21.
//

import SwiftUI
import SwiftUIKit

@main
struct SPENT: App {
    @State var isActive: Bool = false
    @StateObject var globalState: GlobalState = GlobalState()
    @StateObject var dbStore: DatabaseStore = DatabaseStore()
    @StateObject var sheetContext: SheetContext = SheetContext()
    @StateObject var alertContext: AlertContext = AlertContext()
    
    var body: some Scene {
        WindowGroup {
            if isActive {
                MainView()
                    .sheet(context: sheetContext)
                    .alert(context: alertContext)
                    .environmentObject(globalState)
                    .environmentObject(dbStore)
                    .frame(minWidth: 1000, minHeight: 600)
            } else {
                SplashView(showLoading: false, loadDatabase: loadDB)
                    .frame(minWidth: 1000, minHeight: 600)
                    .sheet(context: sheetContext)
                    .alert(context: alertContext)
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
                        sheetContext.present(FormKeys.account(context: sheetContext, account: nil))
                    }
                }
                
                Button("Change Database") {
                    isActive = false
                }
            }
            
            CommandGroup(after: .appSettings){
                Button("Manage Tags"){
                    WindowKeys.TagManager.open()
                }
                
//                Button("Manage Schedules"){
//                    WindowKeys.ScheduleManager.open()
//                }
                
                Button("Manage Templates"){
                    WindowKeys.TemplateManager.open()
                }
            }
            
            CommandGroup(replacing: .importExport) {
                Menu("Import") {
                    Button("SPENT Dev Legacy") {
                        DispatchQueue.main.async {
                            let agent = SPENTLegacyImportAgent()
                            openFile(allowedTypes: agent.allowedTypes, onConfirm: { selectedFile in
                                executeImportAgent(agent: agent, importURL: selectedFile, database: dbStore)
                            }, onCancel: {})
                        }
                    }
                    Button("SPENT Dev V0") {
                        DispatchQueue.main.async {
                            let agent = SPENTV0ImportAgent()
                            openFile(allowedTypes: agent.allowedTypes, onConfirm: { selectedFile in
                                executeImportAgent(agent: agent, importURL: selectedFile, database: dbStore)
                            }, onCancel: {})
                        }
                    }
                    Button("CSV File") {
                        alertContext.present(AlertKeys.notImplemented)
                    }
                }
                
                Menu("Export As") {
                    Button("CSV File") {
                        alertContext.present(AlertKeys.notImplemented)
                    }
                }
                
//                Button("Export all attachments"){
//                    chooseFolder(onConfirm: { url in
//                        for attachment in dbStore.getAllAttachments() {
//                            do {
//                                try dbStore.exportAttachment(destinationURL: url, attachment: attachment)
//                            } catch {
//                                print(error)
//                            }
//                        }
//                    }, onCancel: {})
//                }
            }
        }
        
        WindowGroup("Tag Manager") {
            TagManagerView().environmentObject(globalState).environmentObject(dbStore).frame(minWidth: 300, minHeight: 300)
        }.handlesExternalEvents(matching: Set(arrayLiteral: WindowKeys.TagManager.rawValue))
        
//        WindowGroup("Schedule Manager") {
//            ScheduleManagerView().environmentObject(globalState).environmentObject(dbStore).frame(minWidth: 300, minHeight: 300)
//        }.handlesExternalEvents(matching: Set(arrayLiteral: WindowKeys.ScheduleManager.rawValue))
        
        WindowGroup("Template Manager") {
            TemplateManagerView().environmentObject(globalState).environmentObject(dbStore).frame(minWidth: 300, minHeight: 300)
        }.handlesExternalEvents(matching: Set(arrayLiteral: WindowKeys.TemplateManager.rawValue))
        
        Settings{
            SettingsView().environmentObject(globalState).environmentObject(dbStore).frameSize()
        }
    
    }
    
    func executeImportAgent(agent: ImportAgent, importURL: URL, database: DatabaseStore) {
        do {
            try agent.importFromURL(url: importURL, database: database)
        } catch {
            print(error)
            alertContext.present(AlertKeys.message(message: "Import Failed. \(error.localizedDescription)"))
        }
    }
    
    func loadDB(url: URL, isNew: Bool){
        do {
            try setupDBInstance(url: url, skipHashCheck: isNew)
        } catch {
            print(error)
            alertContext.present(AlertKeys.databaseError(message: "Failed to load database!"))
        }
    }
    
    func setupDBInstance(url: URL, skipHashCheck: Bool = false) throws {
        print("startAccessingSecurityScopedResource")
        if url.startAccessingSecurityScopedResource(){
            print("OK")
            let printQueries = UserDefaults.standard.bool(forKey: PreferenceKeys.debugQueries.rawValue)
            let appDB = try AppDatabase(path: url, trace: printQueries)
            if checkDBCommit(database: appDB) {
                dbStore.load(appDB)
                isActive = true
            } else {
                let gitCommit: String = Bundle.main.object(forInfoDictionaryKey: "GIT_COMMIT_HASH") as? String ?? "(NIL)"
                
                if !skipHashCheck {
                    let upgradeMessage = "The current git hash is \(gitCommit), the hash in the database doesn't match. Load Anyway?"
                    sheetContext.present(FormKeys.confirmAction(context: sheetContext, message: upgradeMessage, onConfirm: {
                        setDBCommit(database: appDB, commit: gitCommit)
                        dbStore.load(appDB)
                        isActive = true
                    }, onCancel: {
                        isActive = false
                    }))
                } else {
                    // Assume the answer was yes
                    setDBCommit(database: appDB, commit: gitCommit)
                    dbStore.load(appDB)
                    isActive = true
                }
            }
        } else {
            print("FAIL")
        }
    }
    
    func checkDBCommit(database: AppDatabase) -> Bool {
        do {
            // Check the saved commit hash against ours before handing the raw db to the db store
            let config = try database.databaseReader.read { db in
                try AppConfiguration.fetch(db)
            }
            let currentHash = Bundle.main.object(forInfoDictionaryKey: "GIT_COMMIT_HASH") as? String ?? "1234567890"
            print("DB Version: \(AppDatabase.DB_VERSION), Loaded Version: \(config.dbVersion)")
            print("\(config.commitHash) vs. \(currentHash)")
            if config.commitHash == currentHash {
                if globalState.debugMode {
                    print("Hash matched")
                }
                return true
            }
        } catch {
            print(error)
        }
        if globalState.debugMode {
            print("Hash didn't match")
        }
        return false
    }
    
    func setDBCommit(database: AppDatabase, commit: String){
        do {
            try database.transaction { db in
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
    
    func getRecents() -> [DBFileBookmark] {
        var bookmarks: [DBFileBookmark] = []
        if let dbBookmarks = UserDefaults.standard.array(forKey: PreferenceKeys.databaseBookmark.rawValue) as? [Data] {
            for bookmData in dbBookmarks {
                var isStale = false
                if let url = getURLByBookmark(bookmData, isStale: &isStale) {
                    let bookmark = DBFileBookmark(shortName: url.pathComponents.last ?? url.absoluteString, path: url)
                    bookmarks.append(bookmark)
                } else {
                    print("Recent Bookmark -> URL failed")
                }
            }
        } else {
            print("Recent Bookmark Failed")
        }
        return bookmarks
    }
}
