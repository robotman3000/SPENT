//
//  TagEditForm.swift
//  iOS
//
//  Created by Eric Nims on 4/21/21.
//

import SwiftUI

struct TagForm: View {
    let title: String
    @State var tag: Tag = Tag(id: nil, name: "")
    
    let onSubmit: (_ data: inout Tag) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack{
            Form {
                TextField("Name", text: $tag.name)
                TextField("Memo", text: $tag.memo)
            }//.navigationTitle(Text(title))
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
        }
    }
}
