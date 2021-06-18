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
    @StateObject var formController: FormManager = FormManager()
    
    var body: some Scene {
        DocumentGroup(newDocument: SPENTDatabaseDocument()) { file in
            if isActive {
                MainView(file: file, activeSheet: $activeSheet)
            } else {
                SplashView(showLoading: true).frame(minWidth: 800, minHeight: 600).onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0) { // Change `2.0` to the desired number of seconds.
                        print("Initializing State Controller")
                        isActive = true
                    }
                }
            }
        }.commands {
            CommandGroup(after: CommandGroupPlacement.newItem) {
                Menu("Create") {
                    Button("Transaction") { activeSheet = .transaction }
                    Button("Bucket") { activeSheet = .bucket }
                    Button("Tag") { activeSheet = .tag }
                }
            }
        }
        
        Settings{
            VStack {
                Text("Settings Window")
            }.padding()
            
        }
    }
}

struct MainView: View {
    @State var file: FileDocumentConfiguration<SPENTDatabaseDocument>
    @Binding var activeSheet: CommandMenuSheet?
    
    var body: some View {
        NavigationView {
            MacSidebar()
                .navigationTitle("Accounts")
                .sheet(item: $activeSheet) { sheet in
                    switch sheet {
                    case .transaction:
                        TransactionForm(title: "Create Transaction", onSubmit: createTransaction, onCancel: {activeSheet = nil}).padding()
                    case .bucket:
                        BucketForm(title: "Create Bucket", onSubmit: createBucket, onCancel: {activeSheet = nil}).padding()
                    case .tag:
                        TagForm(title: "Create Tag", onSubmit: createTag, onCancel: {activeSheet = nil}).padding()
                    }
                }
            MacHome()
        }.environment(\.appDatabase, file.document.database)
    }
    
    func createTransaction(_ data: inout Transaction){
        print(data)
        do {
            try file.document.database.saveTransaction(&data)
            activeSheet = nil
        } catch {
            print(error)
        }
    }
    
    func createBucket(_ data: inout Bucket){
        print(data)
        do {
            try file.document.database.saveBucket(&data)
            activeSheet = nil
        } catch {
            print(error)
        }
    }
    
    func createTag(_ data: inout Tag){
        print(data)
        do {
            try file.document.database.saveTag(&data)
            activeSheet = nil
        } catch {
            print(error)
        }
    }
}

enum CommandMenuSheet : String, Identifiable {
    case transaction, bucket, tag
    
    var id: String { return self.rawValue }
}

enum SidebarListOptions: String, CaseIterable, Identifiable {
    case bucket
    case tag
    
    var id: String { self.rawValue }
}

extension SidebarListOptions {
    var name: String {
        switch self {
        case .bucket: return "Buckets"
        case .tag: return "Tags"
        }
    }
}
