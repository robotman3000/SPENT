//
//  QueryWrapperView.swift
//  SPENT
//
//  Created by Eric Nims on 7/3/21.
//

import SwiftUI

struct QueryWrapperView<Source: Queryable, Content: View>: View {
    @Query<Source> var query: Source.Value
    var content: (Source.Value) -> Content

    init(source: Source, @ViewBuilder content: @escaping (Source.Value) -> Content) {
        self._query = Query(source)
        self.content = content
    }
    
    var body: some View {
        content(query)
    }
}

//struct QueryWrapperView_Previews: PreviewProvider {
//    static var previews: some View {
//        QueryWrapperView()
//    }
//}
