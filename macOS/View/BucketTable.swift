//
//  BucketTable.swift
//  SPENT
//
//  Created by Eric Nims on 6/19/21.
//

import SwiftUI

struct BucketTable: View {
    
    @Environment(\.appDatabase) private var database: AppDatabase?
    @Query(BucketRequest(order: .byTree)) var buckets: [Bucket]
    @State var selected: Bucket?
    @State var activeSheet : ActiveSheet? = nil
    @State var activeAlert : ActiveAlert? = nil
    
    var body: some View {
        VStack {
            Section(header:
                VStack {
                    HStack {
                        TableToolbar(selected: $selected, activeSheet: $activeSheet, activeAlert: $activeAlert)
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
            List(buckets, id: \.self, selection: $selected){ bucket in
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
                ]).tag(bucket)
            }
        }.sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .new:
                BucketForm(title: "Create Bucket", onSubmit: {data in
                    updateBucket(&data, database: database!, onComplete: dismissModal)
                }, onCancel: dismissModal).padding()
            case .edit:
                BucketForm(title: "Edit Bucket", bucket: selected!, onSubmit: {data in
                    updateBucket(&data, database: database!, onComplete: dismissModal)
                }, onCancel: dismissModal).padding()
            }
        }.alert(item: $activeAlert) { alert in
            switch alert {
            case .deleteFail:
                return Alert(
                    title: Text("Database Error"),
                    message: Text("Failed to delete bucket"),
                    dismissButton: .default(Text("OK"))
                )
            case .selectSomething:
                return Alert(
                    title: Text("Alert"),
                    message: Text("Select a bucket first"),
                    dismissButton: .default(Text("OK"))
                )
            case .confirmDelete:
                return Alert(
                    title: Text("Confirm Delete"),
                    message: Text("Are you sure you want to delete this?"),
                    primaryButton: .cancel(),
                    secondaryButton: .destructive(Text("Confirm"), action: {
                        deleteBucket(selected!.id!, database: database!)
                    })
                )
            }
        }
    }
    
    func dismissModal(){
        activeSheet = nil
    }
}

//struct BucketTable_Previews: PreviewProvider {
//    static var previews: some View {
//        BucketTable()
//    }
//}
