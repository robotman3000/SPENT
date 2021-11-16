//
//  TemplateManagerView.swift
//  macOS
//
//  Created by Eric Nims on 10/5/21.
//

import SwiftUI
import SwiftUIKit

struct TemplateManagerView: View {
    @EnvironmentObject fileprivate var store: DatabaseStore
    @State var selected: Int64?
    @State var filter: String = ""
    @StateObject private var sheetContext = SheetContext()
    @StateObject private var alertContext = AlertContext()
    
    var body: some View {
        if store.database != nil {
            VStack{
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            sheetContext.present(FormKeys.transactionTemplate(context: sheetContext, template: nil))
                        }) {
                            Image(systemName: "plus")
                        }
                        TextField("", text: $filter).disabled(true)
                        Spacer()
                    }
                    Spacer()
                }.height(32)
                
                QueryWrapperView(source: TemplateFilter()){ templateIDs in
                    TemplateListView(ids: templateIDs)
                }
            }.sheet(context: sheetContext).alert(context: alertContext)
        } else {
            Text("No database is loaded")
        }
    }
}

struct TemplateManagerView_Previews: PreviewProvider {
    static var previews: some View {
        TemplateManagerView()
    }
}
