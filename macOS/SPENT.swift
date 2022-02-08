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
                    Button("CSV File") {
                        sheetContext.present(ImportExportViewKeys.importCSV(context: sheetContext, alertContext: alertContext))
                    }
                }
                
                Menu("Export As") {
                    Button("CSV File") {
                        sheetContext.present(ImportExportViewKeys.exportCSV(context: sheetContext, alertContext: alertContext))
                    }
                }
            }
        }
        
//        WindowGroup("Tag Manager") {
//            TagManagerView().environmentObject(globalState).environmentObject(dbStore).frame(minWidth: 300, minHeight: 300)
//        }.handlesExternalEvents(matching: Set(arrayLiteral: WindowKeys.TagManager.rawValue))
        
//        WindowGroup("Template Manager") {
//            TemplateManagerView().environmentObject(globalState).environmentObject(dbStore).frame(minWidth: 300, minHeight: 300)
//        }.handlesExternalEvents(matching: Set(arrayLiteral: WindowKeys.TemplateManager.rawValue))
        
        Settings{
            SettingsView()
        }
    }
}
