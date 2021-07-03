//
//  TableToolbar.swift
//  SPENT
//
//  Created by Eric Nims on 6/19/21.
//

import SwiftUI

struct TableToolbar<Type>: View {
    
    @Binding var selected: Type?
    @Binding var activeSheet : ActiveSheet?
    @Binding var activeAlert : ActiveAlert?
    
    var body: some View {
        HStack{
            Button(action: { activeSheet = .new }) {
                Image(systemName: "plus")
            }
            Button(action: {
                if selected != nil {
                    activeSheet = .edit
                } else {
                    activeAlert = .selectSomething
                }
            }) {
                Image(systemName: "square.and.pencil")
            }
            Button(action: {
                if selected != nil {
                    activeAlert = .confirmDelete
                } else {
                    activeAlert = .selectSomething
                }
            }) {
                Image(systemName: "trash")
            }
        }.padding()
    }
}

enum ActiveSheet: String, Identifiable {
    case new, edit
    
    var id: String { return self.rawValue }
}

enum ActiveAlert : String, Identifiable { // <--- note that it's now Identifiable
    case deleteFail, selectSomething, confirmDelete
    
    var id: String { return self.rawValue }
}

struct TableToolbar_Previews: PreviewProvider {
    @State static var selected: String?
    @State static var activeSheet : ActiveSheet?
    @State static var activeAlert : ActiveAlert?
    
    static var previews: some View {
        TableToolbar<String>(selected: $selected, activeSheet: $activeSheet, activeAlert: $activeAlert)
    }
}
