//
//  BucketTable.swift
//  SPENT
//
//  Created by Eric Nims on 6/19/21.
//

import SwiftUI

struct BucketTable: View {
    
    @EnvironmentObject var store: DatabaseStore
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
                    Header()
                }){}
            List(store.buckets, id: \.self, selection: $selected){ bucket in
                Row(bucket: bucket).tag(bucket)
            }
        }.sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .new:
                BucketForm(onSubmit: {data in
                    store.updateBucket(&data, onComplete: dismissModal)
                }, onCancel: dismissModal).padding()
            case .edit:
                BucketForm(bucket: selected!, onSubmit: {data in
                    store.updateBucket(&data, onComplete: dismissModal)
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
                        store.deleteBucket(selected!.id!)
                    })
                )
            }
        }
    }
    
    struct Header: View {
        var body: some View {
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
        }
    }
    
    struct Row: View {
        
        //TODO: This should really be a binding
        @State var bucket: Bucket
        @EnvironmentObject var store: DatabaseStore
        
        var body: some View {
            TableRow(content: [
                AnyView(TableCell {
                    Text(bucket.name)
                }),
                AnyView(TableCell {
                    Text(store.getBucketByID(bucket.parentID)?.name ?? "")
                }),
                AnyView(TableCell {
                    Text(store.getBucketByID(bucket.ancestorID)?.name ?? "")
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
    
    func dismissModal(){
        activeSheet = nil
    }
}

//struct BucketTable_Previews: PreviewProvider {
//    static var previews: some View {
//        BucketTable()
//    }
//}
