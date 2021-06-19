//
//  BucketTable.swift
//  SPENT
//
//  Created by Eric Nims on 6/19/21.
//

import SwiftUI

struct BucketTable: View {
    @Query(BucketRequest(order: .byTree)) var buckets: [Bucket]
    @State var selectedB: Bucket?
    @Binding var activeSheet : ActiveSheet?
    @Binding var activeAlert : ActiveAlert?
    
    var body: some View {
        VStack{
            Section(header:
                VStack {
                    HStack {
                        TableToolbar(selected: $selectedB, activeSheet: $activeSheet, activeAlert: $activeAlert)
                        Spacer()
                    }
                    TableRow(content: [
                        AnyView(TableCell {
                            Text("Name")
                        }),
                        AnyView(TableCell {
                            Text("Parent")
                        }),
                        AnyView(TableCell {
                            Text("Ancestor")
                        }),
                        AnyView(TableCell {
                            Text("Memo")
                        }),
                        AnyView(TableCell {
                            Text("Budget")
                        })
                    ])
                }){}
            List(buckets, id: \.self, selection: $selectedB){ bucket in
                TableRow(content: [
                    AnyView(TableCell {
                        Text(bucket.name)
                    }),
                    AnyView(TableCell {
                        Text("\(bucket.parentID ?? -1)")
                    }),
                    AnyView(TableCell {
                        Text("\(bucket.ancestorID ?? -1)")
                    }),
                    AnyView(TableCell {
                        Text(bucket.memo)
                    }),
                    AnyView(TableCell {
                        Text("\(bucket.budgetID ?? -1)")
                    })
                ])
            }
        }
    }
}

//struct BucketTable_Previews: PreviewProvider {
//    static var previews: some View {
//        BucketTable()
//    }
//}
