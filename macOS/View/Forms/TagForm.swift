//
//  TagEditForm.swift
//  iOS
//
//  Created by Eric Nims on 4/21/21.
//

import SwiftUI
import SwiftUIKit

struct TagForm: View {
    @StateObject fileprivate var aContext: AlertContext = AlertContext()
    @State var tag: Tag
    
    let onSubmit: (_ data: inout Tag) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            Section(){
                TextField("Name", text: $tag.name)
                TextEditor(text: $tag.memo).border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            }
        }
        .toolbar(content: {
            ToolbarItem(placement: .confirmationAction){
                Button("Done", action: {
                    if storeState() {
                        onSubmit(&tag)
                    } else {
                        aContext.present(AlertKeys.message(message: "Invalid input"))
                    }
                })
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: {
                    onCancel()
                })
            }
        })
        .frame(minWidth: 300, minHeight: 200)
        .alert(context: aContext)
    }
    
    func storeState() -> Bool {
        if tag.name.isEmpty {
            return false
        }
        
        return true
    }
}
