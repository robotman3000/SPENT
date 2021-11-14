//
//  TagListView.swift
//  macOS
//
//  Created by Eric Nims on 11/13/21.
//

import SwiftUI
import SwiftUIKit

struct TagListView: View {
    @EnvironmentObject var store: DatabaseStore
    @StateObject var sheetContext: SheetContext = SheetContext()
    @StateObject var alertContext: AlertContext = AlertContext()
    @State var selected = Set<Int64>()
    let ids: [Int64]
    
    var body: some View {
        List(selection: $selected) {
            if ids.isEmpty {
                Text("No Tags")
            }
            
            ForEach(ids, id: \.self){ tagID in
                TagListRow(forID: tagID).contextMenu {
                    AsyncContentView(source: TagFilter.publisher(store.getReader(), forID: tagID)){ model in
                        Button("New Tag"){
                            updateTag(tag: nil)
                        }

                        Button("Edit Tag"){
                            updateTag(tag: model)
                        }

                        Button("Delete Tag"){
                            deleteTag(tag: model)
                        }
                    }
                }
            }
        }
        .contextMenu {
            Button("New Tag"){
                updateTag(tag: nil)
            }
        }
        .sheet(context: sheetContext)
        .alert(context: alertContext)
    }
    
    
    func updateTag(tag: Tag?){
        sheetContext.present(FormKeys.tag(context: sheetContext, tag: tag))
    }
    
    func deleteTag(tag: Tag){
        sheetContext.present(FormKeys.confirmDelete(context: sheetContext, message: "", onConfirm: {
            store.deleteTag(tag.id!, onError: { error in alertContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
        }))
    }
}

//struct TagListView_Previews: PreviewProvider {
//    static var previews: some View {
//        TagListView()
//    }
//}
