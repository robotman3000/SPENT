//
//  WelcomeSheet.swift
//  macOS
//
//  Created by Eric Nims on 8/24/21.
//

import SwiftUI
import Foundation
import UniformTypeIdentifiers

struct WelcomeSheet: View {
    @Binding var showWelcomeSheet: Bool
    var recentFiles: [DBFileBookmark]
    let loadDatabase: (_ path: URL, _ isNew: Bool) -> Void
    @State var selected: DBFileBookmark?
    
    var body: some View {
        VStack {
            Text("Recents")
            List(selection: $selected) {
                //TODO: Show recently used databases here
                // For now we will show the last opened DB
                ForEach(recentFiles){ dbbm in
                    HStack{
                        Text(dbbm.shortName)
                    }.tag(dbbm)
                    Divider()
                }
            }
            HStack{
                Button("New Database"){
                    newDBAction()
                }
                Button("Open Database"){
                    openDBAction()
                }
            }
            
            HStack {
                Button("Load Selected"){
                    loadRecentDBAction(recent: selected!)
                }.disabled(selected == nil)
            }
            
            Button("Quit"){
                exit(0)
            }
        }.padding().frame(width: 500, height: 300, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
    
    func newDBAction(){
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
                loadDatabase(url, true)
            }
        }, onCancel: {
            showWelcomeSheet.toggle()
        })
    }
    
    func openDBAction(){
        showWelcomeSheet.toggle()
        openFile(allowedTypes: [.spentDatabase], onConfirm: { selectedFile in
            if selectedFile.startAccessingSecurityScopedResource() {
                defer { selectedFile.stopAccessingSecurityScopedResource() }
                loadDatabase(selectedFile, false)
            }
        }, onCancel: {
            showWelcomeSheet.toggle()
        })
    }
    
    func loadRecentDBAction(recent: DBFileBookmark){
        showWelcomeSheet.toggle()
        if recent.path.startAccessingSecurityScopedResource() {
            defer { recent.path.stopAccessingSecurityScopedResource() }
            loadDatabase(recent.path, false)
        }
    }
}

struct WelcomeSheet_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeSheet(showWelcomeSheet: .constant(true), recentFiles: [], loadDatabase: {_,_  in})
    }
}
