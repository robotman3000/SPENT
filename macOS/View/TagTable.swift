//
//  TagTable.swift
//  SPENT
//
//  Created by Eric Nims on 6/19/21.
//

import SwiftUI

struct TagTable: View {
    
    @Query(TagRequest(order: .none)) var tags: [Tag]
    @State var selectedT: Tag?
    @Binding var activeSheet : ActiveSheet?
    @Binding var activeAlert : ActiveAlert?
    
    var body: some View {
        VStack{
            Section(header:
                VStack {
                    HStack {
                        TableToolbar(selected: $selectedT, activeSheet: $activeSheet, activeAlert: $activeAlert)
                        Spacer()
                    }
                    TableRow(content: [
                        AnyView(TableCell {
                            Text("Name")
                        }),
                        AnyView(TableCell {
                            Text("Memo")
                        })
                    ])
                }){}
            List(tags, id: \.self, selection: $selectedT){ tag in
                TableRow(content: [
                    AnyView(TableCell {
                        Text(tag.name)
                    }),
                    AnyView(TableCell {
                        Text(tag.memo)
                    })
                ])
            }
        }
    }
}

//struct TagTable_Previews: PreviewProvider {
//    static var previews: some View {
//        TagTable()
//    }
//}
