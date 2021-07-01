//
//  macOSApp.swift
//  macOS
//
//  Created by Eric Nims on 4/14/21.
//

import SwiftUI
import GRDB

extension URL {
    var typeIdentifier: String? { (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier }
    var localizedName: String? { (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName }
}

@main
struct SPENTmacOS: App {
    @State var isActive: Bool = false
    @State var activeSheet: CommandMenuSheet? = nil
    @StateObject var globalState: GlobalState = GlobalState()
    @StateObject var dbStore: DatabaseStore = DatabaseStore()
    
//    import Foundation
//
//    let filePath = NSHomeDirectory() + "/Documents/" + "test.txt"
//    if (FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)) {
//        print("File created successfully.")
//    } else {
//        print("File not created.")
//    }
    
    var body: some Scene {
        WindowGroup {
            if isActive {
                MainView(activeSheet: $activeSheet)
                    .environmentObject(globalState).environmentObject(dbStore).environment(\.appDatabase, dbStore.database!)
            } else {
                SplashView(showLoading: true).frame(minWidth: 1000, minHeight: 600).onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // Change `2.0` to the desired number of seconds.
                        print("Initializing State Controller")
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = false
                        panel.canChooseFiles = true
                        panel.allowedContentTypes = [.spentDatabase]
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
                            let panel = NSSavePanel()
                            //panel.allowsMultipleSelection = false
                            //panel.canChooseDirectories = false
                            //panel.canChooseFiles = true
                            panel.allowedContentTypes = [.spentDatabase]
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
                                exit(0)
                            }
                        }
                    }
                }
            }
        }.commands {
            CommandGroup(after: .newItem) {
                Menu("Create") {
                    Button("Transaction") { activeSheet = .transaction }
                    Button("Bucket") { activeSheet = .bucket }
                    Button("Tag") { activeSheet = .tag }
                }
                
                Menu("Import") {
                    Button("SPENT Dev Legacy") {
                        DispatchQueue.main.async {
                            importSPENTLegacy()
                        }
                    }
                }
                
                Menu("Export As") {
//                    Button("Transaction") { activeSheet = .transaction }
//                    Button("Bucket") { activeSheet = .bucket }
//                    Button("Tag") { activeSheet = .tag }
                }
            }
            
//            CommandGroup(after: .textEditing) {
//                Button("Database") { activeSheet = .manager }
//            }
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
                                let amount: Double = row["Amount"]
                                var source: Int64? = row["SourceBucket"]
                                var destination: Int64? = row["DestBucket"]
                                let memo: String = row["Memo"] ?? ""
                                let payee: String? = row["Payee"]
                            
                                // Update the status value
                                let newStatus = statusMap[status] ?? .Void
                                
                                // Convert the amount from a floating point to an int
                                let newAmount = Int(amount * 1000.00) / 10
                                
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

struct MainView: View {
    @EnvironmentObject var store: DatabaseStore
    //@State var file: FileDocumentConfiguration<SPENTDatabaseDocument>
    @Binding var activeSheet: CommandMenuSheet?
    
    var body: some View {
        NavigationView {
            MacSidebar()
                .frame(minWidth: 300)
                .navigationTitle("Accounts")
                .sheet(item: $activeSheet) { sheet in
                    switch sheet {
                    case .transaction:
                        TransactionForm(title: "Create Transaction", onSubmit: {data in
                            store.updateTransaction(&data, onComplete: dismissModal)
                        }, onCancel: dismissModal).padding()
                    case .bucket:
                        BucketForm(title: "Create Bucket", onSubmit: {data in
                            store.updateBucket(&data, onComplete: dismissModal)
                        }, onCancel: dismissModal).padding()
                    case .tag:
                        TagForm(title: "Create Tag", onSubmit: {data in
                            store.updateTag(&data, onComplete: dismissModal)
                        }, onCancel: dismissModal).padding()
                    case .manager:
                        DatabaseManagerView(onCancel: { activeSheet = nil })
                    }
                }
            MacHome()
        }
    }
    
    func dismissModal(){
        activeSheet = nil
    }
}

struct SettingsView: View {
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
            
            BucketTable()
                .tabItem {
                    Label("Accounts", systemImage: "folder")
                }.tag(Tabs.buckets)
         
            ScheduleTable()
                .tabItem {
                    Label("Schedules", systemImage: "calendar.badge.clock")
                }.tag(Tabs.schedules)
     
            TagTable()
                .tabItem {
                    Label("Tags", systemImage: "tag")
                }.tag(Tabs.tags)
                
        }
        .padding(20)
        .frame(width: 600, height: 400)
    }
}

struct GeneralSettingsView: View {
    //@AppStorage("showPreview") private var showPreview = true
    //@AppStorage("fontSize") private var fontSize = 12.0

    var body: some View {
//        Form {
//            Toggle("Show Previews", isOn: $showPreview)
//            Slider(value: $fontSize, in: 9...96) {
//                Text("Font Size (\(fontSize, specifier: "%.0f") pts)")
//            }
//        }
        Text("Nothing to see here!")
        .padding(20)
        .frame(width: 350, height: 100)
    }
}

class GlobalState: ObservableObject {
    @Published var selectedView = TransactionViewType.Table
    @Published var contextBucket: Bucket?
}

enum CommandMenuSheet : String, Identifiable {
    case transaction, bucket, tag, manager
    
    var id: String { return self.rawValue }
}
