//
//  WindowKeys.swift
//  macOS
//
//  Created by Eric Nims on 8/26/21.
//

import SwiftUI

enum WindowKeys: String, CaseIterable {
    case MainWindow = ""
    case DatabaseManager = "databaseManager"
    
    func open(){
        if let url = URL(string: "SPENT://\(self.rawValue)") {
            NSWorkspace.shared.open(url)
        }
    }
}
