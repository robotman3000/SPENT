//
//  TagEditForm.swift
//  iOS
//
//  Created by Eric Nims on 4/21/21.
//

import SwiftUI

struct TagForm: View {
    @State var tag: Tag = Tag(id: nil, name: "")
    
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
                    onSubmit(&tag)
                })
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: {
                    onCancel()
                })
            }
        })
        .frame(minWidth: 300, minHeight: 200)
    }
}
