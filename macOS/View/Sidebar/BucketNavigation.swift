//
//  BucketNavigation.swift
//  macOS
//
//  Created by Eric Nims on 6/8/21.
//

import SwiftUI

struct BucketNavigation: View {

    @EnvironmentObject var store: DatabaseStore
    @State var selectedBucket: Bucket?
    @State private var showingAlert = false
    @State private var showingForm = false
    
    var body: some View {
        //BalanceTable(model: BucketBalanceViewModel(bucket: _selectedBuck)).padding()
        BalanceTable(bucket: $selectedBucket)
        List(selection: $selectedBucket) {
            Section(header: Text("Accounts")){
                OutlineGroup(store.bucketTree, id: \.bucket, children: \.children) { node in
                    NavigationLink(destination: MacTransactionView(contextBucket: node.bucket).onAppear(perform: {print("Mac transa view appear")})) {
                        BucketRow(bucket: node.bucket).onAppear(perform: {
                            print("Row Appeared: \(node.bucket.name)")
                        })
                    }
                    .contextMenu {
                        Button("Edit") {
                            showingForm.toggle()
                        }
                    }
                }
            }//.collapsible(false)
        }.listStyle(SidebarListStyle())
        
        .onDeleteCommand {
            store.deleteBucket(selectedBucket!.id!, onComplete: dismissModal, onError: { _ in showingAlert.toggle() })
        }
        .sheet(isPresented: $showingForm) {
            BucketForm(title: "Edit Bucket", bucket: selectedBucket!, onSubmit: {data in
                store.updateBucket(&data, onComplete: dismissModal, onError: { _ in showingAlert.toggle() })
            }, onCancel: dismissModal).padding()
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Database Error"),
                message: Text("Failed to delete account"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    func dismissModal(){
        showingForm = false
        showingAlert = false
    }
}

//struct BucketNavigation_Previews: PreviewProvider {
//    static var previews: some View {
//        BucketNavigation()
//    }
//}
