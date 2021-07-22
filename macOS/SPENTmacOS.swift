//
//  macOSApp.swift
//  macOS
//
//  Created by Eric Nims on 4/14/21.
//

import SwiftUI
import GRDB
import Foundation

@main
struct SPENTmacOS: App {
    @State var isActive: Bool = false
    @State var showWelcomeSheet: Bool = false
    @State var isDBSwitch: Bool = false
    @StateObject var globalState: GlobalState = GlobalState()
    @StateObject var dbStore: DatabaseStore = DatabaseStore()
    
    var body: some Scene {
        WindowGroup {
            if isActive {
                NavigationView {
                    MacSidebar(bucketTree: dbStore.bucketTree, schedules: dbStore.schedules, tags: dbStore.tags)
                        .frame(minWidth: 300)
                        .navigationTitle("Accounts")
                }.environmentObject(globalState).environmentObject(dbStore).environment(\.appDatabase, dbStore.database!)
            } else {
                SplashView(showLoading: true).frame(minWidth: 1000, minHeight: 600).onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now()) {
                        print("Initializing State Controller")
                        print("Source Version: \(Bundle.main.object(forInfoDictionaryKey: "GIT_COMMIT_HASH") ?? "(NIL)")")
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
                .sheet(isPresented: $showWelcomeSheet, content: {
                    VStack {
                        Button("New Database"){
                            let panel = NSSavePanel()
                            panel.allowedContentTypes = [.spentDatabase]
                            showWelcomeSheet.toggle()
                            if panel.runModal() == .OK {
                                let selectedFile = panel.url?.absoluteURL
                                if selectedFile != nil {
                                    if selectedFile!.startAccessingSecurityScopedResource() {
                                        if !FileManager.default.fileExists(atPath: selectedFile!.path) {
                                            do {
                                                try FileManager.default.createDirectory(atPath: selectedFile!.path, withIntermediateDirectories: true, attributes: nil)
                                            } catch {
                                                print(error.localizedDescription)
                                            }
                                        }
                                        defer { selectedFile!.stopAccessingSecurityScopedResource() }
                                        let database = AppDatabase(path: selectedFile!)
                                        dbStore.load(database)
                                        isActive = true
                                    }
                                }
                            } else {
                                showWelcomeSheet.toggle()
                            }
                        }
                        Button("Open Database"){
                            let panel = NSOpenPanel()
                            panel.allowsMultipleSelection = false
                            panel.canChooseDirectories = false
                            panel.canChooseFiles = true
                            panel.allowedContentTypes = [.spentDatabase]
                            showWelcomeSheet.toggle()
                            if panel.runModal() == .OK {
                                let selectedFile = panel.url?.absoluteURL
                                if selectedFile != nil {
                                    if selectedFile!.startAccessingSecurityScopedResource() {
                                        defer { selectedFile!.stopAccessingSecurityScopedResource() }
                                        let database = AppDatabase(path: selectedFile!)
                                        dbStore.load(database)
                                        isActive = true
                                    }
                                }
                            } else {
                                showWelcomeSheet.toggle()
                            }
                        }
                        Button("Quit"){
                            exit(0)
                        }
                    }.padding().frame(width: 300, height: 200, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                })
            }
        }.commands {
            CommandGroup(after: .newItem) {
                
                Section{
                    Button("New Account") {
                    }
                    
                    Button("New Transaction") {
                    }
                    
                    Button("New Transfer") {
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
                                importSPENTLegacy()
                            }
                        }
                        Button("CSV File") {
                            DispatchQueue.main.async {}
                        }
                    }
                    
                    Menu("Export As") {
                        Button("CSV File") {
                            DispatchQueue.main.async {}
                        }
                    }
                }
            }
        }
        
        Settings{
            SettingsView().environmentObject(globalState).environmentObject(dbStore).environment(\.appDatabase, dbStore.database)
        }
    }
    
    func importSPENTLegacy(){
        //TODO: This function will eventually need to be split up and moved into the import and export manager (Once ready)
        
        // Select our legacy db
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK {
            let selectedFile = panel.url?.absoluteURL
            if selectedFile != nil {
                if selectedFile!.startAccessingSecurityScopedResource() {
                    defer { selectedFile!.stopAccessingSecurityScopedResource() }
                    
                    do {
                        // Then connect to it
                        let dbQueue = try DatabaseQueue(path: selectedFile!.absoluteString)
                        
                        // And proceed to read everything into memory
                        
                        /* Note: We are able to create the new database objects using the old data
                         because the old and new still bear a close resemblance. This is subject to change
                         */
                        var buckets: [Bucket] = []
                        var tags: [Tag] = []
                        var transactions: [Transaction] = []
                        var transactionTags: [TransactionTag] = []
                        
                        try dbQueue.read { db in
                            // Start with the buckets/accounts
                            let bucketRows = try Row.fetchCursor(db, sql: "SELECT * FROM Buckets")
                            while let row = try bucketRows.next() {
                                let id: Int64 = row["id"]
                                let name: String = row["Name"]
                                var parent: Int64? = row["Parent"]
                                var ancestor: Int64? = row["Ancestor"]
                                
                                // Skip the "ROOT" account
                                if id == -1 {
                                    continue
                                }
                                
                                // Remove/fix all references to the ROOT account
                                if parent == -1 || parent == nil {
                                    parent = nil
                                }
                                if ancestor == -1 || ancestor == nil {
                                    ancestor = nil
                                }
                                
                                // Create the new db object
                                buckets.append(Bucket(id: id, name: name, parentID: parent, ancestorID: ancestor, memo: "", budgetID: nil))
                            }
                            
                            // Then fetch the tags
                            let tagRows = try Row.fetchCursor(db, sql: "SELECT * FROM Tags")
                            while let row = try tagRows.next() {
                                let id: Int64 = row["id"]
                                let name: String = row["Name"]
                            
                                // Create the new db object
                                tags.append(Tag(id: id, name: name, memo: ""))
                            }
                            
                            // Followed by the transactions
                            let statusMap: [Int : Transaction.StatusTypes] = [0: .Void, 1: .Uninitiated, 2: .Submitted, 3: .Posting, 4: .Complete, 5: .Reconciled]
                            let dateFormatter = DateFormatter()
                            dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
                            dateFormatter.dateFormat = "yyyy-MM-dd"
                            let transactionRows = try Row.fetchCursor(db, sql: "SELECT * FROM Transactions")
                            while let row = try transactionRows.next() {
                                let id: Int64 = row["id"]
                                let status: Int = row["Status"]
                                let date: String = row["TransDate"]
                                let postDate: String? = row["PostDate"]
                                let amount: String = row["Amount"]
                                var source: Int64? = row["SourceBucket"]
                                var destination: Int64? = row["DestBucket"]
                                let memo: String = row["Memo"] ?? ""
                                let payee: String? = row["Payee"]
                            
                                // Update the status value
                                let newStatus = statusMap[status] ?? .Void
                                
                                // Convert the amount from a floating point to an int
                                let newAmount = Int(round(Double(amount)! * 100))
                                
                                let newDate = dateFormatter.date(from:date)!
                                let newPDate = dateFormatter.date(from:postDate ?? "")
                                
                                // Remove/fix all references to the ROOT account
                                if source == -1 || source == nil {
                                    source = nil
                                }
                                if destination == -1 || destination == nil {
                                    destination = nil
                                }
                                
                                // Create the new db object
                                transactions.append(Transaction(id: id, status: newStatus, date: newDate, posted: newPDate, amount: newAmount, sourceID: source, destID: destination, memo: memo, payee: payee, group: nil))
                            }
                            
                            
                            // And finally the tag assignments (TransactionTags)
                            let tTagRows = try Row.fetchCursor(db, sql: "SELECT * FROM TransactionTags")
                            while let row = try tTagRows.next() {
                                let id: Int64 = row["id"]
                                let tag: Int64 = row["TagID"]
                                let transaction: Int64 = row["TransactionID"]
                                
                                // Create the new db object
                                transactionTags.append(TransactionTag(id: id, transactionID: transaction, tagID: tag))
                            }
                        }
                        
                        try dbStore.database!.getWriter().write { db in
                            // Having created all the database objects, we now proceed to store them
                            // We turn off foreign key verification so that we don't have any "doesn't exist when needed" issues
                            
                            for var bucket in buckets {
                                try bucket.save(db)
                            }
                            
                            for var tag in tags {
                                try tag.save(db)
                            }
                            
                            for var transaction in transactions {
                                try transaction.save(db)
                            }
                            
                            for var tTag in transactionTags {
                                try tTag.save(db)
                            }
                        }
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var dbStore: DatabaseStore
    
    private enum Tabs: Hashable {
        case general, buckets, schedules, tags
    }
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
        }
        .padding(20)
        .frame(width: 600, height: 400)
    }
}

struct GeneralSettingsView: View {
    @AppStorage(PreferenceKeys.autoloadDB.rawValue) private var autoloadDB = false

    @State var showError = false
    var body: some View {
        Form {
            Toggle("Load DB on start", isOn: $autoloadDB)
            Section {
                Text("Selected Database:")
                if let data = UserDefaults.standard.data(forKey: PreferenceKeys.databaseBookmark.rawValue) {
                    var isStale = false
                    if let url = getURLByBookmark(data, isStale: &isStale) {
                        Text(url.absoluteString)
                    }
                }
                Button("Change DB") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.canChooseFiles = true
                    panel.allowedContentTypes = [.spentDatabase]
                    if panel.runModal() == .OK {
                        let selectedFile = panel.url?.absoluteURL
                        if let file = selectedFile {
                            if file.startAccessingSecurityScopedResource() {
                                defer { file.stopAccessingSecurityScopedResource() }
                                do {
                                    let bookmarkData = try file.bookmarkData(options: URL.BookmarkCreationOptions.withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                                    UserDefaults.standard.setValue(bookmarkData, forKey: PreferenceKeys.databaseBookmark.rawValue)
                                } catch {
                                    print(error)
                                    showError.toggle()
                                }
                            }
                        }
                    }
                }
            }
        }.alert(isPresented: $showError){
            Alert(
                title: Text("Error"),
                message: Text("Failed to update database path"),
                dismissButton: .default(Text("OK")) {
                    showError.toggle()
                }
            )
        }
        .padding(20)
    }
}

func getURLByBookmark(_ data: Data, isStale: inout Bool) -> URL? {
    do {
        return try URL(resolvingBookmarkData: data,
                  options: URL.BookmarkResolutionOptions.withSecurityScope,
                  relativeTo: nil, bookmarkDataIsStale: &isStale)
    } catch {
        print(error)
    }
    return nil
}

enum PreferenceKeys: String {
    case autoloadDB
    case databaseBookmark
}
