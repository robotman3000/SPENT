//
//  BucketTableRow.swift
//  SPENT
//
//  Created by Eric Nims on 6/18/21.
//

import SwiftUI

struct TableRow: View {
    
    let content: [AnyView]
    let showDivider: Bool
    
    init(content: [AnyView], showDivider: Bool = true) {
        self.content = content
        self.showDivider = showDivider
    }
    var body: some View {
        if showDivider {
            Spacer(minLength: 5)
        }
        HStack(alignment: .center) {
            ForEach(self.content.indices){ item in
                content[item]
            }
        }
        if showDivider {
            Spacer(minLength: 5)
            Divider()
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
