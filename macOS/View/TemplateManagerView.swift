//
//  TemplateManagerView.swift
//  macOS
//
//  Created by Eric Nims on 10/5/21.
//

import SwiftUI
import SwiftUIKit
import GRDBQuery

struct TemplateManagerView: View {
    @Query(AllTemplates(), in: \.dbQueue) var templates: [TransactionTemplate]
    @State var selected: TransactionTemplate? = nil as TransactionTemplate?
    @StateObject private var sheetContext = SheetContext()
    @StateObject private var aContext = AlertContext()
    
    var body: some View {
        VStack{
            VStack {
                HStack {
                    Button(action: {
                        sheetContext.present(FormKeys.transactionTemplate(context: sheetContext, template: nil))
                    }) {
                        Image(systemName: "plus")
                    }
                    Spacer()
                }
            }.padding()
            
            List(selection: $selected) {
                ForEach(templates){ template in
                    Text(template.getName()).contextMenu { ContextMenu(sheet: sheetContext, forTemplate: template) }.tag(template)
                }
            }
        }.sheet(context: sheetContext).alert(context: aContext)
    }
    
    private struct ContextMenu: View {
        @EnvironmentObject var databaseManager: DatabaseManager
        @ObservedObject var sheet: SheetContext
        let forTemplate: TransactionTemplate
        
        var body: some View {
            Button("Edit template") {
                sheet.present(FormKeys.transactionTemplate(context: sheet, template: forTemplate))
            }
            Button("Delete template") {
                databaseManager.action(.deleteTransactionTemplate(forTemplate), onSuccess: {
                    print("deleted template successfully")
                })
            }
        }
    }
}

//struct TemplateManagerView_Previews: PreviewProvider {
//    static var previews: some View {
//        TemplateManagerView()
//    }
//}
