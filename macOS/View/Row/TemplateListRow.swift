//
//  TemplateListRow.swift
//  macOS
//
//  Created by Eric Nims on 11/16/21.
//

import SwiftUI

struct TemplateListRow: View {
    @EnvironmentObject var store: DatabaseStore
    let forID: Int64
    
    var body: some View {
        AsyncContentView(source: TemplateFilter.publisher(store.getReader(), forID: forID), "TemplateListRow") { model in
            Internal_TemplateListRow(model: model)
        }
    }
}

private struct Internal_TemplateListRow: View {
    let model: DBTransactionTemplate
    
    var body: some View {
        Text(model.templateData?.name ?? "Error while decoding template")
    }
}

//struct TemplateListRow_Previews: PreviewProvider {
//    static var previews: some View {
//        TemplateListRow()
//    }
//}
