//
//  BucketTableRow.swift
//  SPENT
//
//  Created by Eric Nims on 6/18/21.
//

import SwiftUI

struct TableRow: View {
    
    let content: [AnyView]
        
    init(content: [AnyView]) {
        self.content = content
    }
    var body: some View {
        HStack(alignment: .center) {
            ForEach(self.content.indices){ item in
                content[item]
            }
        }
    }
}

struct TableCell<Content: View>: View {
    let content: Content
        
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack{
            self.content
        }.frame(maxWidth: .infinity)
    }
}

struct TableRow_Previews: PreviewProvider {
    static var previews: some View {
        TableRow(content: [])
    }
}
