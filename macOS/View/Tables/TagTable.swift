//
//  TagTable.swift
//  SPENT
//
//  Created by Eric Nims on 6/19/21.
//

import SwiftUI
import SwiftUIKit

struct TagTable: View {
    
    @EnvironmentObject var store: DatabaseStore
    @StateObject private var context = SheetContext()
    @StateObject private var aContext = AlertContext()
    
    var tags: [Tag]
    @State var selected: Tag?

    var body: some View {
        VStack{
            Section(header:
                VStack {
                    HStack {
                        TableToolbar(onClick: { action in
                            switch action {
                            case .new:
                                context.present(UIForms.tag(context: context, tag: nil, onSubmit: {data in
                                    store.updateTag(&data, onComplete: { context.dismiss() })
                                }))
                            case .edit:
                                if selected != nil {
                                    context.present(UIForms.tag(context: context, tag: selected!, onSubmit: {data in
                                        store.updateTag(&data, onComplete: { context.dismiss() })
                                    }))
                                } else {
                                    aContext.present(UIAlerts.message(message: "Select a tag first"))
                                }
                            case .delete:
                                if selected != nil {
                                    aContext.present(UIAlerts.confirmDelete(message: "", onConfirm: {
                                        store.deleteTag(selected!.id!)
                                    }))
                                } else {
                                    aContext.present(UIAlerts.message(message: "Select a tag first"))
                                }
                            }
                        })
                        Spacer()
                    }
                    Header()
                }){}
            List(tags, id: \.self, selection: $selected){ tag in
                Row(tag: tag).tag(tag)
            }
        }.sheet(context: context).alert(context: aContext)
    }
    
    struct Header: View {
        var body: some View {
            TableRow(content: [
                AnyView(TableCell {
                    Text("Name")
                }),
                AnyView(TableCell {
                    Text("Memo")
                })
            ], showDivider: false)
        }
    }
    
    struct Row: View {
        
        //TODO: This should really be a binding
        @State var tag: Tag
        
        var body: some View {
            TableRow(content: [
                AnyView(TableCell {
                    Text(tag.name)
                }),
                AnyView(TableCell {
                    Text(tag.memo.trunc(length: 10))
                })
            ], showDivider: false)
        }
    }
}

//struct TagTable_Previews: PreviewProvider {
//    static var previews: some View {
//        TagTable()
//    }
//}
