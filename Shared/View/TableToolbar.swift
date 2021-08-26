//
//  TableToolbar.swift
//  SPENT
//
//  Created by Eric Nims on 6/19/21.
//

import SwiftUI

// TODO: This needs to be removed and dependant code refactored
struct TableToolbar: View {
    let onClick: (_ action: ToolbarAction) -> Void
    
    var body: some View {
        HStack{
            Button(action: { onClick(.new) }) {
                Image(systemName: "plus")
            }
            Button(action: { onClick(.edit) }) {
                Image(systemName: "square.and.pencil")
            }
            Button(action: { onClick(.delete) }) {
                Image(systemName: "trash")
            }
        }.padding()
    }
}

enum ToolbarAction: String, Identifiable {
    case new, edit, delete
    
    var id: String { return self.rawValue }
}

struct TableToolbar_Previews: PreviewProvider {
    
    static var previews: some View {
        TableToolbar(onClick: {_ in})
    }
}
