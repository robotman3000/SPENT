//
//  UIAlerts.swift
//  macOS
//
//  Created by Eric Nims on 7/22/21.
//

import SwiftUI
import SwiftUIKit

enum UIAlerts: AlertProvider {
    case confirmDelete(message: String, onConfirm: () -> Void)
    case databaseError(message: String)
    case message(message: String)
    case notImplemented
    
    
    var alert: Alert {
        switch self {
        case .confirmDelete(message: _, onConfirm: let onConfirm):
            return Alert(
                title: Text("Confirm Delete"),
                message: Text("Are you sure you want to delete this?"),
                primaryButton: .cancel(),
                secondaryButton: .destructive(Text("Confirm"), action: onConfirm)
            )
        case .databaseError(message: let message):
            return Alert(
                title: Text("Database Error"),
                message: Text(message),
                dismissButton: .default(Text("OK"))
            )
        case .notImplemented:
            return Alert(
                title: Text("Feature Missing"),
                message: Text("Sorry, This feature hasn't been added yet"),
                dismissButton: .default(Text("OK"))
            )
        case .message(message: let message):
            return Alert(
                title: Text("Alert"),
                message: Text(message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
