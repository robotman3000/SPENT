//
//  SettingsView.swift
//  macOS
//
//  Created by Eric Nims on 8/24/21.
//

import SwiftUI

struct SettingsView: View {
    private enum Tabs: Hashable {
        case general, buckets, schedules, tags
    }
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
        }
        .padding(20)
        .frame(width: 600, height: 400)
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
