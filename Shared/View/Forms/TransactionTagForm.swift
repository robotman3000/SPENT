//
//  TransactionTagForm.swift
//  SPENT
//
//  Created by Eric Nims on 6/29/21.
//

import SwiftUI

import SwiftUI

struct TransactionTagForm: View {
    @State var transaction: Transaction
    @State var tags: Set<Tag>
    @Query(TagRequest()) var dbTags: [Tag]
    
    let onSubmit: (_ tags: [Tag], _ transaction: Transaction) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Form {
            List(dbTags, id: \.self, selection: $tags) { tag in
                Text("\(tag.name)")
            }
        }
        .toolbar(content: {
            ToolbarItem(placement: .confirmationAction){
                Button("Done", action: {
                    onSubmit(Array(tags), transaction)
                })
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: {
                    onCancel()
                })
            }
        }).frame(minWidth: 300, minHeight: 300)
    }
}


//struct TransactionTagForm_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionTagForm()
//    }
//}
