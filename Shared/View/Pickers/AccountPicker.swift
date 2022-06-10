//
//  AccountPicker.swift
//  macOS
//
//  Created by Eric Nims on 2/3/22.
//

import SwiftUI

struct AccountPicker: View {
    var label: String = ""
    @Binding var selection: Account?
    let choices: [Account]
    
    var body: some View {
        if !choices.isEmpty {
            Picker(selection: $selection, label: Text(label)) {
                ForEach(choices, id: \.id) { account in
                    Text(account.name).tag(account as Account?)
                }
            }
        } else {
            Text("No Accounts")
        }
    }
}
