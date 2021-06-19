//
//  TagTable.swift
//  SPENT
//
//  Created by Eric Nims on 6/19/21.
//

import SwiftUI

struct TagTable: View {
    
    @Environment(\.appDatabase) private var database: AppDatabase?
    @Query(TagRequest(order: .none)) var tags: [Tag]
    @State var selected: Tag?
    @Binding var activeSheet : ActiveSheet?
    @Binding var activeAlert : ActiveAlert?
    
    var body: some View {
        VStack{
            Section(header:
                VStack {
                    HStack {
                        TableToolbar(selected: $selected, activeSheet: $activeSheet, activeAlert: $activeAlert)
                        Spacer()
                    }
                    TableRow(content: [
                        AnyView(TableCell {
                            Text("Name")
                        }),
                        AnyView(TableCell {
                            Text("Memo")
                        })
                    ])
                }){}
            List(tags, id: \.self, selection: $selected){ tag in
                TableRow(content: [
                    AnyView(TableCell {
                        Text(tag.name)
                    }),
                    AnyView(TableCell {
                        Text(tag.memo)
                    })
                ]).tag(tag)
            }
        }.sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .new:
                TagForm(title: "Create Tag", onSubmit: {data in
                    updateTag(&data, database: database!, onComplete: dismissModal)
                }, onCancel: dismissModal).padding()
            case .edit:
                TagForm(title: "Edit Tag", tag: selected!, onSubmit: {data in
                    updateTag(&data, database: database!, onComplete: dismissModal)
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
                        deleteTag(selected!.id!, database: database!)
                    })
                )
            }
        }
    }
    
    func dismissModal(){
        activeSheet = nil
    }
}

//struct TagTable_Previews: PreviewProvider {
//    static var previews: some View {
//        TagTable()
//    }
//}
