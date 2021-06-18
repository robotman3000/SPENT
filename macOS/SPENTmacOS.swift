//
//  macOSApp.swift
//  macOS
//
//  Created by Eric Nims on 4/14/21.
//

import SwiftUI
import GRDB

// Let SwiftUI views access the database through the SwiftUI environment
private struct AppDatabaseKey: EnvironmentKey {
    static let defaultValue: AppDatabase? = nil
}

extension EnvironmentValues {
    var appDatabase: AppDatabase? {
        get { print("adb get \(self[AppDatabaseKey.self])"); return self[AppDatabaseKey.self] }
        set { print("adb set \(newValue)"); self[AppDatabaseKey.self] = newValue }
    }
}

extension URL {
    var typeIdentifier: String? { (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier }
    var localizedName: String? { (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName }
}

@main
struct SPENTmacOS: App {
    @State var isActive: Bool = false
    @StateObject var formController: FormManager = FormManager()
    
    var body: some Scene {
        DocumentGroup(newDocument: SPENTDatabaseDocument()) { file in
            if isActive {
                MainView(file: file, formController: formController)
            } else {
                SplashView(showLoading: true).frame(minWidth: 800, minHeight: 600).onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0) { // Change `2.0` to the desired number of seconds.
                        print("Initializing State Controller")
                        isActive = true
//                        stateController.initStore {
//                            print("Ready!!")
//
//                        }
                    }
                }
            }
        }.commands {
//            CommandMenu("Vieeew") {
//                Button("Print message") {
//                    print("Hello World!")
//                }.keyboardShortcut("p")
//            }
            CommandGroup(after: CommandGroupPlacement.newItem) {
                Menu("Create") {
                    Button("Transaction") {
                        formController.showTransactionForm.toggle()
                    }
                    Button("Bucket") {
                        formController.showBucketForm.toggle()
                    }
                    Button("Tag") {
                        print("New Tag")
                        formController.showTagForm.toggle()
                    }
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
    @ObservedObject var formController: FormManager
    
    var body: some View {
        NavigationView {
            MacSidebar()
                .navigationTitle("Accounts")
                .sheet(isPresented: $formController.showTransactionForm) {
                    TransactionForm(title: "Create Transaction", onSubmit: { data in
                        print(data)
                        do {
                            try file.document.database.saveTransaction(&data)
                            formController.showTransactionForm.toggle()
                        } catch {
                            print(error)
                        }
                    }, onCancel: {formController.showTransactionForm.toggle()})
                    .padding()
                }
                .sheet(isPresented: $formController.showBucketForm) {
                    BucketForm(title: "Create Bucket", onSubmit: { data in
                        print(data)
                        do {
                            try file.document.database.saveBucket(&data)
                            formController.showBucketForm.toggle()
                        } catch {
                            print(error)
                        }
                    }, onCancel: {formController.showBucketForm.toggle()})
                    .padding()
                }
                .sheet(isPresented: $formController.showTagForm) {
                    TagForm(title: "Create Tag", onSubmit: { data in
                        print(data)
                        do {
                            try file.document.database.saveTag(&data)
                            formController.showTagForm.toggle()
                        } catch {
                            print(error)
                        }
                    }, onCancel: {formController.showTagForm.toggle()})
                    .padding()
                }
            MacHome()
        }.environment(\.appDatabase, file.document.database)
    }
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
