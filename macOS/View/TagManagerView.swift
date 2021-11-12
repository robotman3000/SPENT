//
//  TagManagerView.swift
//  macOS
//
//  Created by Eric Nims on 8/26/21.
//

import SwiftUI
import SwiftUIKit
import Combine

struct TagManagerView: View {
    @EnvironmentObject fileprivate var store: DatabaseStore
    @State var selected: Int64?
    @State var filter: String = ""
    @StateObject private var context = SheetContext()
    @StateObject private var aContext = AlertContext()
    
    var body: some View {
        if store.database != nil {
            VStack{
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        TableToolbar(onClick: { action in
                            switch action {
                            case .new:
                                updateTag(tag: nil)
                            case .edit:
                                if let tag = selected {
                                    //updateTag(tag: tag)
                                } else {
                                    aContext.present(AlertKeys.message(message: "Select a tag first"))
                                }
                            case .delete:
                                if let tag = selected {
                                    //deleteTag(tag: tag)
                                } else {
                                    aContext.present(AlertKeys.message(message: "Select a tag first"))
                                }
                            }
                        })
                        TextField("", text: $filter)
                        Spacer()
                    }
                    Spacer()
                }.height(32)
                
                QueryWrapperView(source: TagFilter(nameLike: filter, order: .byName)){ tagIDs in
                    List(tagIDs, id: \.self, selection: $selected) { tagID in
                        AsyncContentView(source: TagFilter.publisher(store.getReader(), forID: tagID)){ tag in
                            Text(tag.name).contextMenu {
                                Button("New Tag"){
                                    updateTag(tag: nil)
                                }

                                Button("Edit Tag"){
                                    updateTag(tag: tag)
                                }

                                Button("Delete Tag"){
                                    deleteTag(tag: tag)
                                }
                            }
                        }.tag(tagID)
                    }.listStyle(.plain).contextMenu {
                        Button("New Tag"){
                            updateTag(tag: nil)
                        }
                    }.onAppear(perform: {print("List appear")})
                }
            }.sheet(context: context).alert(context: aContext)
        } else {
            Text("No database is loaded")
        }
    }
    
    func updateTag(tag: Tag?){
        context.present(FormKeys.tag(context: context, tag: tag))
    }
    
    func deleteTag(tag: Tag){
        context.present(FormKeys.confirmDelete(context: context, message: "", onConfirm: {
            store.deleteTag(tag.id!, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
        }))
    }
}

struct TagManagerView_Previews: PreviewProvider {
    static var previews: some View {
        TagManagerView()
    }
}
