//
//  SettingsView.swift
//  iOS
//
//  Created by Eric Nims on 7/8/21.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List{
                NavigationLink(destination: EditAccountListView()){
                    Text("Accounts")
                }
                NavigationLink(destination: Text("B")){
                    Text("Schedules")
                }
                NavigationLink(destination: Text("C")){
                    Text("Tags")
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
