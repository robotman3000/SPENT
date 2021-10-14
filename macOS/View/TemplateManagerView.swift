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
    @State var selected: DBTransactionTemplate?
    @StateObject private var context = SheetContext()
    @StateObject private var aContext = AlertContext()
    
    var body: some View {
        if store.database != nil {
            VStack{
                VStack {
                    Spacer()
                    TableToolbar(onClick: { action in
                        switch action {
                        case .new:
                            updateTemplate(template: nil)
                        case .edit:
                            if let template = selected {
                                updateTemplate(template: template)
                            } else {
                                aContext.present(AlertKeys.message(message: "Select a template first"))
                            }
                        case .delete:
                            if let template = selected {
                                deleteTemplate(template: template)
                            } else {
                                aContext.present(AlertKeys.message(message: "Select a template first"))
                            }
                        }
                    })
                    Spacer()
                }.height(32)
                

                QueryWrapperView(source: TemplateRequest()){ templates in
                    List(templates, id: \.self, selection: $selected){ template in
                        if let tempData = template.templateData {
                            Text(tempData.name).contextMenu {
                                Button("New Template"){
                                    updateTemplate(template: nil)
                                }
                                
                                Button("Edit Template"){
                                    updateTemplate(template: template)
                                }
                                
                                Button("Delete Template"){
                                    deleteTemplate(template: template)
                                }
                            }
                        } else {
                            Text("Undecoded Template")
                        }
                    }.listStyle(.plain).contextMenu {
                        Button("New Template"){
                            updateTemplate(template: nil)
                        }
                    }
                }
            }.sheet(context: context).alert(context: aContext)
        } else {
            Text("No database is loaded")
        }
    }
    
    func updateTemplate(template: DBTransactionTemplate?){
        context.present(FormKeys.transactionTemplate(context: context, template: template, onSubmit: {data in
            store.updateTemplate(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
        }))
    }
    
    func deleteTemplate(template: DBTransactionTemplate){
        context.present(FormKeys.confirmDelete(context: context, message: "", onConfirm: {
            store.deleteTemplate(selected!.id!, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
        }))
    }
}

struct TemplateManagerView_Previews: PreviewProvider {
    static var previews: some View {
        TemplateManagerView()
    }
}
