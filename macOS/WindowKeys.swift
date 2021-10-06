//
//  WindowKeys.swift
//  macOS
//
//  Created by Eric Nims on 8/26/21.
//

import SwiftUI

enum WindowKeys: String, CaseIterable {
    case MainWindow = ""
    case TagManager = "tagManager"
    case ScheduleManager = "scheduleManager"
    case TemplateManager = "templateManager"
    
    func open(){
        if let url = URL(string: "SPENT://\(self.rawValue)") {
            NSWorkspace.shared.open(url)
        }
    }
}
