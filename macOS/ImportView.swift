//
//  ImportExportView.swift
//  macOS
//
//  Created by Eric Nims on 2/8/22.
//

import Foundation
import SwiftUI
import GRDB
import SwiftUIKit

struct ImportView: View {
    let agent: ImportAgent
    let database: DatabaseQueue
    @ObservedObject var alertContext: AlertContext
    var onFinished: () -> Void
    var onCancel: () -> Void
    
    @State var file: URL?

    var body: some View {
        Group {
            Text(agent.displayName)
            HStack {
                Text("\(file?.absoluteString ?? "No File Selected")")
                Spacer()
                Button(action: {
                    chooseFile()
                }) {
                    Text("Choose File")
                }
            }
            
            HStack {
                Spacer()
                Button(action: onCancel) {
                    Text("Cancel")
                }
                Button(action: {
                    //TODO: Async import
                    // DispatchQueue.main.async {}
                    if let sourceFile = file {
                        executeImportAgent(agent: agent, importURL: sourceFile, database: database)
                        onFinished()
                    } else {
                        alertContext.present(AlertKeys.message(message: "No File Selected"))
                    }
                }) {
                    Text("Import")
                }
            }
        }.frame(minWidth: 250).padding()
    }
    
    func chooseFile(){
        openFile(allowedTypes: agent.allowedTypes, onConfirm: { url in
            self.file = url
        }, onCancel: {})
    }
    
    func executeImportAgent(agent: ImportAgent, importURL: URL, database: DatabaseQueue) {
        do {
            try agent.importFromURL(url: importURL, database: database)
            alertContext.present(AlertKeys.message(message: "Import finished without errors"))
        } catch {
            print(error)
            alertContext.present(AlertKeys.message(message: "Import Failed. \(error.localizedDescription)"))
        }
    }
}
