//
//  TagListRow.swift
//  SPENT
//
//  Created by Eric Nims on 10/16/21.
//

import SwiftUI
import Combine
import GRDB
import SwiftUIKit

struct TagListRow: View {
    @EnvironmentObject var store: DatabaseStore
    let forID: Int64
    
    var body: some View {
        AsyncContentView(source: TagFilter.publisher(store.getReader(), forID: forID)) { model in
            Internal_TagListRow(model: model)
        }
    }
}

private struct Internal_TagListRow: View {
    let model: Tag
    
    var body: some View {
        Text(model.name)
    }
}

//struct TagListRow_Previews: PreviewProvider {
//    static var previews: some View {
//        TagListRow()
//    }
//}
