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
        get { self[AppDatabaseKey.self] }
        set { self[AppDatabaseKey.self] = newValue }
    }
}

@main
struct SPENTmacOS: App {
    @State var isActive: Bool = false
    let stateController: StateController = StateController()
    @StateObject var formController: FormManager = FormManager()
    
    var body: some Scene {
        WindowGroup {
            if isActive {
                MainView(formController: formController).environment(\.appDatabase, stateController.database).environmentObject(stateController)
            } else {
                SplashView(showLoading: true).frame(minWidth: 800, minHeight: 600).onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0) { // Change `2.0` to the desired number of seconds.
                        print("Initializing State Controller")
                        stateController.initStore {
                            print("Ready!!")
                            isActive = true
                        }
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
    }
}

struct MainView: View {
    
    @EnvironmentObject var stateController: StateController
    @ObservedObject var formController: FormManager
    
    var body: some View {
        NavigationView {
            MacSidebar()
                .navigationTitle("Accounts")
                .sheet(isPresented: $formController.showTransactionForm) {
                    TransactionForm(title: "Create Transaction", onSubmit: createNewTransaction, onCancel: {formController.showTransactionForm.toggle()})
                    .padding()
                }
                .sheet(isPresented: $formController.showBucketForm) {
                    BucketForm(title: "Create Bucket", onSubmit: createNewBucket, onCancel: {formController.showBucketForm.toggle()})
                    .padding()
                }
                .sheet(isPresented: $formController.showTagForm) {
                    TagForm(title: "Create Tag", onSubmit: createNewTag, onCancel: {formController.showTagForm.toggle()})
                    .padding()
                }
            MacHome()
        }
    }
    
    func createNewTransaction(data: inout Transaction){
        print(data)
        do {
            try stateController.database.saveTransaction(&data)
            formController.showTransactionForm.toggle()
        } catch {
            print(error)
        }
    }
    
    func createNewTag(data: inout Tag){
        print(data)
        do {
            try stateController.database.saveTag(&data)
            formController.showTagForm.toggle()
        } catch {
            print(error)
        }
    }
    
    func createNewBucket(data: inout Bucket){
        print(data)
        do {
            try stateController.database.saveBucket(&data)
            formController.showBucketForm.toggle()
        } catch {
            print(error)
        }
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
