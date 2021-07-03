//
//  MacHome.swift
//  macOS
//
//  Created by Eric Nims on 6/8/21.
//

import SwiftUI

struct MacHome: View {
    @State var filename = "Filename"
    @State var showFileChooser = false
    
    var body: some View {
        Text("Welcome to SPENT!")
    }
}

struct MacHome_Previews: PreviewProvider {
    static var previews: some View {
        MacHome()
    }
}
