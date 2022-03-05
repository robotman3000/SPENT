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
            CommandGroup(after: .appSettings){
                Button("Database"){
                    sheetContext.present(FormKeys.manageDatabase(context: sheetContext))
                }
            }
            
            CommandGroup(after: .newItem){
                Menu("Create") {
                    Button("Account"){
                        sheetContext.present(FormKeys.account(context: sheetContext, account: nil))
                    }
                    Button("Bucket"){
                        sheetContext.present(FormKeys.bucket(context: sheetContext, bucket: nil))
                    }
                    Button("Transaction"){
                        sheetContext.present(FormKeys.transaction(context: sheetContext, transaction: nil))
                    }
                    Button("Transfer"){
                        sheetContext.present(FormKeys.transfer(context: sheetContext, transfer: nil))
                    }
                    Button("Split Transaction"){
                        sheetContext.present(FormKeys.splitTransaction(context: sheetContext, split: nil))
                    }
                }
            }
            
            CommandGroup(replacing: .importExport) {
                ImportExportCommands(sheetContext: sheetContext, alertContext: alertContext)
            }
        }
        
        Settings{
            SettingsView()
        }
    }
}

private struct ImportExportCommands: View {
    @ObservedObject var sheetContext: SheetContext
    @ObservedObject var alertContext: AlertContext
    
    var body: some View {
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
