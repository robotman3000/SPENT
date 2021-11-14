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
    @StateObject private var sheetContext = SheetContext()
    @StateObject private var aContext = AlertContext()
    
    var body: some View {
        if store.database != nil {
            VStack{
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            sheetContext.present(FormKeys.tag(context: sheetContext, tag: nil))
                        }) {
                            Image(systemName: "plus")
                        }
                        TextField("", text: $filter)
                        Spacer()
                    }
                    Spacer()
                }.height(32)
                
                QueryWrapperView(source: TagFilter(nameLike: filter, order: .byName)){ tagIDs in
                    TagListView(ids: tagIDs)
                }
            }.sheet(context: sheetContext).alert(context: aContext)
        } else {
            Text("No database is loaded")
        }
    }
}

struct TagManagerView_Previews: PreviewProvider {
    static var previews: some View {
        TagManagerView()
    }
}
