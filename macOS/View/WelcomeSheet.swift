//
//  WelcomeSheet.swift
//  macOS
//
//  Created by Eric Nims on 8/24/21.
//

import SwiftUI
import UniformTypeIdentifiers

struct WelcomeSheet: View {
    @Binding var showWelcomeSheet: Bool
    let loadDatabase: (_ path: URL) -> Void
    
    var body: some View {
        VStack {
            Button("New Database"){
                showWelcomeSheet.toggle()
                saveFile(allowedTypes: [.spentDatabase], onConfirm: {url in
                    if url.startAccessingSecurityScopedResource() {
                        if !FileManager.default.fileExists(atPath: url.path) {
                            do {
                                try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                        defer { url.stopAccessingSecurityScopedResource() }
                        loadDatabase(url)
                    }
                }, onCancel: {
                    showWelcomeSheet.toggle()
                })
            }
            Button("Open Database"){
                showWelcomeSheet.toggle()
                openFile(allowedTypes: [.spentDatabase], onConfirm: { selectedFile in
                    if selectedFile.startAccessingSecurityScopedResource() {
                        defer { selectedFile.stopAccessingSecurityScopedResource() }
                        loadDatabase(selectedFile)
                    }
                }, onCancel: {
                    showWelcomeSheet.toggle()
                })
            }
            Button("Quit"){
                exit(0)
            }
        }.padding().frame(width: 300, height: 200, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
}

struct WelcomeSheet_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeSheet(showWelcomeSheet: .constant(true), loadDatabase: {_ in})
    }
}
