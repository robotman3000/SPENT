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
    
    var body: some Scene {
        DocumentGroup(newDocument: SPENTDatabaseDocument()) { file in
            if isActive {
                MainView(file: file, activeSheet: $activeSheet).environmentObject(globalState)
            } else {
                SplashView(showLoading: true).frame(minWidth: 1000, minHeight: 600).onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0) { // Change `2.0` to the desired number of seconds.
                        print("Initializing State Controller")
                        isActive = true
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
            }
            CommandGroup(after: .textEditing) {
                Button("Database") { activeSheet = .manager }
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
                .frame(minWidth: 300)
                .navigationTitle("Accounts")
                .sheet(item: $activeSheet) { sheet in
                    switch sheet {
                    case .transaction:
                        TransactionForm(title: "Create Transaction", onSubmit: {data in
                            updateTransaction(&data, database: file.document.database, onComplete: dismissModal)
                        }, onCancel: dismissModal).padding()
                    case .bucket:
                        BucketForm(title: "Create Bucket", onSubmit: {data in
                            updateBucket(&data, database: file.document.database, onComplete: dismissModal)
                        }, onCancel: dismissModal).padding()
                    case .tag:
                        TagForm(title: "Create Tag", onSubmit: {data in
                            updateTag(&data, database: file.document.database, onComplete: dismissModal)
                        }, onCancel: dismissModal).padding()
                    case .manager:
                        DatabaseManagerView(onCancel: { activeSheet = nil })
                    }
                }
            MacHome()
        }.environment(\.appDatabase, file.document.database)
    }
    
    func dismissModal(){
        activeSheet = nil
    }
}

class GlobalState: ObservableObject {
    @Published var selectedView = TransactionViewType.Table
}

enum CommandMenuSheet : String, Identifiable {
    case transaction, bucket, tag, manager
    
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
