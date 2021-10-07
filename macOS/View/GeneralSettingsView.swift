//
//  GeneralSettingsView.swift
//  macOS
//
//  Created by Eric Nims on 8/24/21.
//

import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage(PreferenceKeys.debugMode.rawValue) private var debugMode = false
    @AppStorage(PreferenceKeys.debugQueries.rawValue) private var debugQueries = false

    @State var showError = false
    var body: some View {
        Form {
            Toggle("Debug Mode", isOn: $debugMode)
            Toggle("Log SQL Queries", isOn: $debugQueries)
        }
    }
}

struct GeneralSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralSettingsView()
    }
}
