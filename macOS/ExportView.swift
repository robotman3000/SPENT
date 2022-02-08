//
//  ExportView.swift
//  macOS
//
//  Created by Eric Nims on 2/8/22.
//

import SwiftUI
import SwiftUIKit
import GRDB

struct ExportView: View {
    let agent: ExportAgent
    let database: DatabaseQueue
    @ObservedObject var alertContext: AlertContext
    var onFinished: () -> Void
    var onCancel: () -> Void
    
    @State var file: URL?

    var body: some View {
        Group {
            Text(agent.displayName)
            HStack {
                Text("\(file?.absoluteString ?? "No destination selected")")
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
                        executeExportAgent(agent: agent, exportURL: sourceFile, database: database)
                        onFinished()
                    } else {
                        alertContext.present(AlertKeys.message(message: "No destination selected"))
                    }
                }) {
                    Text("Export")
                }
            }
        }.frame(minWidth: 250).padding()
    }
    
    func chooseFile(){
        saveFile(allowedTypes: agent.allowedTypes, onConfirm: { selectedFile in
            self.file = selectedFile
        }, onCancel: {})
    }
    
    func executeExportAgent(agent: ExportAgent, exportURL: URL, database: DatabaseQueue) {
        do {
            try agent.exportToURL(url: exportURL, database: database)
            alertContext.present(AlertKeys.message(message: "Export finished without errors"))
        } catch {
            print(error)
            alertContext.present(AlertKeys.message(message: "Export Failed. \(error.localizedDescription)"))
        }
    }
}
