//
//  TagManagerView.swift
//  macOS
//
//  Created by Eric Nims on 8/26/21.
//

import SwiftUI
import SwiftUIKit
import Combine
import GRDBQuery

struct TagManagerView: View {
    @Query(AllTags(), in: \.dbQueue) var tags: [Tag]
    @State var selected: Tag? = nil as Tag?
    @StateObject private var sheetContext = SheetContext()
    @StateObject private var aContext = AlertContext()
    @State var filter: String = ""
    
    var body: some View {
        VStack{
            VStack {
                HStack {
                    Button(action: {
                        sheetContext.present(FormKeys.tag(context: sheetContext, tag: nil))
                    }) {
                        Image(systemName: "plus")
                    }
                    //TextField("", text: $filter)
                    Spacer()
                }
            }.padding()
            
            List(selection: $selected) {
                ForEach(tags){ tag in
                    Text(tag.name).contextMenu { ContextMenu(sheet: sheetContext, forTag: tag) }.tag(tag)
                }
            }
        }.sheet(context: sheetContext).alert(context: aContext)
    }
    
    private struct ContextMenu: View {
        @EnvironmentObject var databaseManager: DatabaseManager
        @ObservedObject var sheet: SheetContext
        let forTag: Tag
        
        var body: some View {
            Button("Edit tag") {
                sheet.present(FormKeys.tag(context: sheet, tag: forTag))
            }
            Button("Delete \(forTag.name)") {
                databaseManager.action(DeleteTagAction(tag: forTag), onSuccess: {
                    print("deleted tag successfully")
                })
            }
        }
    }
}

//struct TagManagerView_Previews: PreviewProvider {
//    static var previews: some View {
//        TagManagerView()
//    }
//}

