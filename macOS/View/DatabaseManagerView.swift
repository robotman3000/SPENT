//
//  DatabaseManagerView.swift
//  SPENT
//
//  Created by Eric Nims on 6/18/21.
//

import SwiftUI

struct DatabaseManagerView: View {
    
    let onCancel: () -> Void
    
    @Query(BucketRequest(order: .byTree)) var buckets: [Bucket]
    @State var selected: Transaction?
    @State var activeSheet : ActiveSheet? = nil
    @State var activeAlert : ActiveAlert? = nil
    
    var body: some View {
        VStack{
            TabView {
                VStack{
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
                    List(buckets){ bucket in
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
                }.tabItem {
                    Text("Accounts")
                }
             
                Text("Bookmark Tab")
                .tabItem {
                    Text("Schedules")
                }
         
                Text("Video Tab")
                .tabItem {
                    Text("Tags")
                }
            }
            HStack {
                Spacer()
                Button("Done", action: {
                    onCancel()
                })
            }
        }.padding().frame(minWidth: 600, minHeight: 400)
    }
}

//struct DatabaseManagerView_Previews: PreviewProvider {
//    static var previews: some View {
//        DatabaseManagerView()
//    }
//}
