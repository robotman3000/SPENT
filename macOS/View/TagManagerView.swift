//
//  TagManagerView.swift
//  macOS
//
//  Created by Eric Nims on 8/26/21.
//

import SwiftUI
import SwiftUIKit

struct TagManagerView: View {
    @EnvironmentObject fileprivate var store: DatabaseStore
    @State var selected: Tag?
    @StateObject private var context = SheetContext()
    @StateObject private var aContext = AlertContext()
    
    var body: some View {
        VStack{
            HStack {
                TableToolbar(onClick: { action in
                    switch action {
                    case .new:
                        context.present(FormKeys.tag(context: context, tag: nil, onSubmit: {data in
                            store.updateTag(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                        }))
                    case .edit:
                        if selected != nil {
                            context.present(FormKeys.tag(context: context, tag: selected!, onSubmit: {data in
                                store.updateTag(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                            }))
                        } else {
                            aContext.present(AlertKeys.message(message: "Select a tag first"))
                        }
                    case .delete:
                        if selected != nil {
                            context.present(FormKeys.confirmDelete(context: context, message: "", onConfirm: {
                                store.deleteTag(selected!.id!, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                            }))
                        } else {
                            aContext.present(AlertKeys.message(message: "Select a tag first"))
                        }
                    }
                })
                Spacer()
            }
            
            List(store.tags, id: \.self, selection: $selected){ tag in
                Text(tag.name)
                //Row(tag: tag).tag(tag)
            }
        }.sheet(context: context).alert(context: aContext)
    }
}

struct TagManagerView_Previews: PreviewProvider {
    static var previews: some View {
        TagManagerView()
    }
}
