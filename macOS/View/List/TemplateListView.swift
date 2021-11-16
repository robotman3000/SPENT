//
//  TemplateListView.swift
//  macOS
//
//  Created by Eric Nims on 11/16/21.
//

import SwiftUI
import SwiftUIKit

struct TemplateListView: View {
    @EnvironmentObject var store: DatabaseStore
    @StateObject var sheetContext: SheetContext = SheetContext()
    @StateObject var alertContext: AlertContext = AlertContext()
    @State var selected = Set<Int64>()
    let ids: [Int64]
    
    var body: some View {
        List(selection: $selected) {
            if ids.isEmpty {
                Text("No Templates")
            }
            
            ForEach(ids, id: \.self){ templateID in
                TemplateListRow(forID: templateID).contextMenu {
                    AsyncContentView(source: TemplateFilter.publisher(store.getReader(), forID: templateID)){ model in
                        Button("New Template"){
                            updateTemplate(template: nil)
                        }

                        Button("Edit Template"){
                            updateTemplate(template: model)
                        }

                        Button("Delete Template"){
                            deleteTemplate(template: model)
                        }
                    }
                }
            }
        }
        .contextMenu {
            Button("New Template"){
                updateTemplate(template: nil)
            }
        }
        .sheet(context: sheetContext)
        .alert(context: alertContext)
    }
    
    
    func updateTemplate(template: DBTransactionTemplate?){
        sheetContext.present(FormKeys.transactionTemplate(context: sheetContext, template: template))
    }
    
    func deleteTemplate(template: DBTransactionTemplate){
        sheetContext.present(FormKeys.confirmDelete(context: sheetContext, message: "", onConfirm: {
            store.deleteTemplate(template.id!, onError: { error in alertContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
        }))
    }
}

//struct TemplateListView_Previews: PreviewProvider {
//    static var previews: some View {
//        TemplateListView()
//    }
//}
