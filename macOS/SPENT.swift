//
//  macOSApp.swift
//  macOS
//
//  Created by Eric Nims on 4/14/21.
//

import SwiftUI
import SwiftUIKit
import GRDB

private struct DatabaseQueueKey: EnvironmentKey {
    /// The default dbQueue is an empty in-memory database
    static var defaultValue: DatabaseQueue { DatabaseQueue() }
}

extension EnvironmentValues {
    var dbQueue: DatabaseQueue {
        get { self[DatabaseQueueKey.self] }
        set { self[DatabaseQueueKey.self] = newValue }
    }
}

@main
struct SPENT: App {
    static var DB_VERSION: Int64 = 6
    
    //@State var isActive: Bool = false
    @StateObject var globalState: GlobalState = GlobalState()
    @StateObject var sheetContext: SheetContext = SheetContext()
    @StateObject var alertContext: AlertContext = AlertContext()
    
    var body: some Scene {
        DocumentGroup(newDocument: SPENTDatabaseDocument()){ file in
            MainView()
                .sheet(context: sheetContext)
                .alert(context: alertContext)
                .environmentObject(globalState)
                .environmentObject(file.document.manager)
                .environment(\.dbQueue, file.document.manager.database)
                .frame(minWidth: 1000, minHeight: 600)
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
            }
            
            CommandGroup(after: .appSettings){
                Button("Manage Tags"){
                    WindowKeys.TagManager.open()
                }
                
                Button("Manage Templates"){
                    WindowKeys.TemplateManager.open()
                }
            }
            
            CommandGroup(replacing: .importExport) {
                Menu("Import") {
//                    Button("SPENT Dev Legacy") {
//                        DispatchQueue.main.async {
//                            let agent = SPENTLegacyImportAgent()
//                            openFile(allowedTypes: agent.allowedTypes, onConfirm: { selectedFile in
//                                executeImportAgent(agent: agent, importURL: selectedFile, database: dbStore)
//                                alertContext.present(AlertKeys.message(message: "Import finished without errors"))
//                            }, onCancel: {})
//                        }
//                    }
//                    Button("SPENT Dev V0") {
//                        DispatchQueue.main.async {
//                            let agent = SPENTV0ImportAgent()
//                            openFile(allowedTypes: agent.allowedTypes, onConfirm: { selectedFile in
//                                executeImportAgent(agent: agent, importURL: selectedFile, database: dbStore)
//                                alertContext.present(AlertKeys.message(message: "Import finished without errors"))
//                            }, onCancel: {})
//                        }
//                    }
//                    Button("CSV File") {
//                        DispatchQueue.main.async {
//                            let agent = CSVAgent()
//                            openFile(allowedTypes: agent.allowedTypes, onConfirm: { selectedFile in
//                                executeImportAgent(agent: agent, importURL: selectedFile, database: dbStore)
//                                alertContext.present(AlertKeys.message(message: "Import finished without errors"))
//                            }, onCancel: {})
//                        }
//                    }
                }
                
                Menu("Export As") {
//                    Button("CSV File") {
//                        DispatchQueue.main.async {
//                            let agent = CSVAgent()
//                            saveFile(allowedTypes: agent.allowedTypes, onConfirm: { selectedFile in
//                                executeExportAgent(agent: agent, exportURL: selectedFile, database: dbStore)
//                                alertContext.present(AlertKeys.message(message: "Export finished without errors"))
//                            }, onCancel: {})
//                        }
//                    }
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
        
//        WindowGroup("Tag Manager") {
//            TagManagerView().environmentObject(globalState).environmentObject(dbStore).frame(minWidth: 300, minHeight: 300)
//        }.handlesExternalEvents(matching: Set(arrayLiteral: WindowKeys.TagManager.rawValue))
        
//        WindowGroup("Template Manager") {
//            TemplateManagerView().environmentObject(globalState).environmentObject(dbStore).frame(minWidth: 300, minHeight: 300)
//        }.handlesExternalEvents(matching: Set(arrayLiteral: WindowKeys.TemplateManager.rawValue))
        
//        Settings{
//            if globalState.database != nil {
//                SettingsView().environmentObject(globalState).environment(\.dbQueue, globalState.database!).frameSize()
//            } else {
//                Text("No database is loaded")
//            }
//        }
    }
    
    func executeImportAgent(agent: ImportAgent, importURL: URL, database: DatabaseQueue) {
        do {
            try agent.importFromURL(url: importURL, database: database)
        } catch {
            print(error)
            alertContext.present(AlertKeys.message(message: "Import Failed. \(error.localizedDescription)"))
        }
    }
    
    func executeExportAgent(agent: ExportAgent, exportURL: URL, database: DatabaseQueue) {
        do {
            try agent.exportToURL(url: exportURL, database: database)
        } catch {
            print(error)
            alertContext.present(AlertKeys.message(message: "Export Failed. \(error.localizedDescription)"))
        }
    }
    
//    func setupDBInstance(url: URL, skipHashCheck: Bool = false) throws {
//        print("startAccessingSecurityScopedResource")
//        if url.startAccessingSecurityScopedResource(){
//            print("OK")
//            let printQueries = UserDefaults.standard.bool(forKey: PreferenceKeys.debugQueries.rawValue)
//
//            let database = try createDBInstance(path: url, trace: printQueries)
//            if checkDBCommit(database: database) {
//                self.globalState.database = database
//            } else {
//                let gitCommit: String = Bundle.main.object(forInfoDictionaryKey: "GIT_COMMIT_HASH") as? String ?? "(NIL)"
//
//                if !skipHashCheck {
//                    let upgradeMessage = "The current git hash is \(gitCommit), the hash in the database doesn't match. Load Anyway?"
//                    sheetContext.present(FormKeys.confirmAction(context: sheetContext, message: upgradeMessage, onConfirm: {
//                        setDBCommit(database: database, commit: gitCommit)
//                        self.globalState.database = database
//                    }, onCancel: {
//                        self.globalState.database = nil
//                    }))
//                } else {
//                    // Assume the answer was yes
//                    setDBCommit(database: database, commit: gitCommit)
//                    self.globalState.database = database
//                }
//            }
//        } else {
//            print("FAIL")
//        }
//    }
    
    func checkDBCommit(database: DatabaseQueue) -> Bool {
        do {
            // Check the saved commit hash against ours before handing the raw db to the db store
            let config = try database.read { db in
                try AppConfiguration.fetch(db)
            }
            let currentHash = Bundle.main.object(forInfoDictionaryKey: "GIT_COMMIT_HASH") as? String ?? "1234567890"
            print("DB Version: \(SPENT.DB_VERSION), Loaded Version: \(config.dbVersion)")
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
    
    func setDBCommit(database: DatabaseQueue, commit: String){
        do {
            try database.write { db in
                var config = try AppConfiguration.fetch(db)
                
                // Update some config values
                try config.updateChanges(db) {
                    $0.commitHash = commit
                    $0.dbVersion = SPENT.DB_VERSION
                }
            }
        } catch {
            print("Failed to update database commit hash")
            print(error)
        }
    }
    
//    func resolve<Type: FetchableRecord>(_ query: QueryInterfaceRequest<Type>) -> [Type] {
//        do {
//            return try databaseReader.read { db in
//                return try query.fetchAll(db)
//            }
//        } catch {
//            print(error)
//        }
//        return []
//    }
//
//    func resolveOne<Type: FetchableRecord>(_ query: QueryInterfaceRequest<Type>) -> Type? {
//        do {
//            return try databaseReader.read { db in
//                return try query.fetchOne(db)
//            }
//        } catch {
//            print(error)
//        }
//        return nil
//    }
}
