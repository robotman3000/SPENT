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
                HStack {
                    TableToolbar(onClick: { action in
                        switch action {
                        case .new:
                            context.present(FormKeys.transactionTemplate(context: context, template: nil, onSubmit: {data in
                                store.updateTemplate(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                            }))
                        case .edit:
                            if selected != nil {
                                context.present(FormKeys.transactionTemplate(context: context, template: selected!, onSubmit: {data in
                                    store.updateTemplate(&data, onComplete: { context.dismiss() }, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                                }))
                            } else {
                                aContext.present(AlertKeys.message(message: "Select a template first"))
                            }
                        case .delete:
                            if selected != nil {
                                context.present(FormKeys.confirmDelete(context: context, message: "", onConfirm: {
                                    store.deleteTemplate(selected!.id!, onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                                }))
                            } else {
                                aContext.present(AlertKeys.message(message: "Select a template first"))
                            }
                        }
                    })
                    Spacer()
                }
                

                QueryWrapperView(source: TemplateRequest()){ templates in
                    List(templates, id: \.self, selection: $selected){ template in
                        Text(template.template)
                    }
                }
            }.sheet(context: context).alert(context: aContext)
        } else {
            Text("No database is loaded").frame(width: 100, height: 100)
        }
    }
}

struct TemplateManagerView_Previews: PreviewProvider {
    static var previews: some View {
        TemplateManagerView()
    }
}
