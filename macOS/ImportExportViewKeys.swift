//
//  ImportExportViewKeys.swift
//  macOS
//
//  Created by Eric Nims on 2/8/22.
//

import Foundation
import SwiftUIKit
import SwiftUI
import GRDB

enum ImportExportViewKeys: SheetProvider {
    case importCSV(context: SheetContext, alertContext: AlertContext)
    case exportCSV(context: SheetContext, alertContext: AlertContext)
    
    var sheet: AnyView {
        ImportExportViewWrapper { database in
            switch self {
            case let .importCSV(context: context, alertContext: alertContext):
                ImportView(agent: CSVAgent(), database: database, alertContext: alertContext, onFinished: { context.dismiss() }, onCancel: { context.dismiss() })
            case let .exportCSV(context: context, alertContext: alertContext):
                ExportView(agent: CSVAgent(), database: database, alertContext: alertContext, onFinished: { context.dismiss() }, onCancel: { context.dismiss() })
            }
        }.any()
    }
}

// Wrapper to provide the database without exposing it through the parent views
private struct ImportExportViewWrapper<Content: View>: View {
    @Environment(\.dbQueue) var database
    var content: (DatabaseQueue) -> Content
    
    init(@ViewBuilder content: @escaping (DatabaseQueue) -> Content){
        self.content = content
    }
    
    var body: some View {
        content(database)
    }
}
