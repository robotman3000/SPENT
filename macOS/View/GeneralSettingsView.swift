//
//  GeneralSettingsView.swift
//  macOS
//
//  Created by Eric Nims on 8/24/21.
//

import SwiftUI

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

struct GeneralSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralSettingsView()
    }
}
