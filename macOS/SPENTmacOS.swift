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
    
    var body: some Scene {
        DocumentGroup(newDocument: SPENTDatabaseDocument()) { file in
            if isActive {
                MainView(file: file, activeSheet: $activeSheet).environmentObject(globalState).environmentObject(dbStore).environment(\.appDatabase, file.document.database)
            } else {
                SplashView(showLoading: true).frame(minWidth: 1000, minHeight: 600).onAppear {
                    isActive = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // Change `2.0` to the desired number of seconds.
                        print("Initializing State Controller")
                        dbStore.load(file.document.database)
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
    @EnvironmentObject var store: DatabaseStore
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

class GlobalState: ObservableObject {
    @Published var selectedView = TransactionViewType.Table
    @Published var contextBucket: Bucket?
}

enum CommandMenuSheet : String, Identifiable {
    case transaction, bucket, tag, manager
    
    var id: String { return self.rawValue }
}
