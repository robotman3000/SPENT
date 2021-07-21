//
//  TagTable.swift
//  SPENT
//
//  Created by Eric Nims on 6/19/21.
//

import SwiftUI

struct TagTable: View {
    
    @EnvironmentObject var store: DatabaseStore
    var tags: [Tag]
    @State var selected: Tag?
    @State var activeSheet : ActiveSheet? = nil
    @State var activeAlert : ActiveAlert? = nil
    
    var body: some View {
        VStack{
            Section(header:
                VStack {
                    HStack {
                        TableToolbar(selected: $selected, activeSheet: $activeSheet, activeAlert: $activeAlert)
                        Spacer()
                    }
                    Header()
                }){}
            List(tags, id: \.self, selection: $selected){ tag in
                Row(tag: tag).tag(tag)
            }
        }.sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .new:
                TagForm(onSubmit: {data in
                    store.updateTag(&data, onComplete: dismissModal)
                }, onCancel: dismissModal).padding()
            case .edit:
                TagForm(tag: selected!, onSubmit: {data in
                    store.updateTag(&data, onComplete: dismissModal)
                }, onCancel: dismissModal).padding()
            }
        }.alert(item: $activeAlert) { alert in
            switch alert {
            case .deleteFail:
                return Alert(
                    title: Text("Database Error"),
                    message: Text("Failed to delete tag"),
                    dismissButton: .default(Text("OK"))
                )
            case .selectSomething:
                return Alert(
                    title: Text("Alert"),
                    message: Text("Select a tag first"),
                    dismissButton: .default(Text("OK"))
                )
            case .confirmDelete:
                return Alert(
                    title: Text("Confirm Delete"),
                    message: Text("Are you sure you want to delete this?"),
                    primaryButton: .cancel(),
                    secondaryButton: .destructive(Text("Confirm"), action: {
                        store.deleteTag(selected!.id!)
                    })
                )
            }
        }
    }
    
    func dismissModal(){
        activeSheet = nil
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
