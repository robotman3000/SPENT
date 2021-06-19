//
//  TagNavigation.swift
//  macOS
//
//  Created by Eric Nims on 6/8/21.
//

import SwiftUI

struct TagNavigation: View, SidebarNavigable {
        
    @Environment(\.appDatabase) private var database: AppDatabase?
    @State var selectedTag: Tag?
    @Query(TagRequest()) var tags: [Tag]
    @State private var showingAlert = false
    @State private var showingForm = false

    var body: some View {
        List(selection: $selectedTag) {
            Section(header: Text("Tags")){
                ForEach(Array(tags.enumerated()), id: \.element) { index, tag in
                    NavigationLink(destination: MacTransactionView(title: tag.name, query: TransactionRequest(tag))) {
                        Text(tag.name)
                    }
                    .contextMenu {
                        Button("Edit") {
                            showingForm.toggle()
                        }
                    }
                }
            }//.collapsible(false)
        }
        .onDeleteCommand {
            deleteTag(selectedTag!.id!, database: database!, onComplete: dismissModal, onError: { _ in showingAlert.toggle() })
        }
        .sheet(isPresented: $showingForm) {
            TagForm(title: "Edit Tag", tag: selectedTag!, onSubmit: {data in
                updateTag(&data, database: database!, onComplete: dismissModal, onError: { _ in showingAlert.toggle() })
            }, onCancel: dismissModal).padding()
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Database Error"),
                message: Text("Failed to delete tag"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    func dismissModal(){
        showingForm = false
        showingAlert = false
    }
    
}

//struct TagNavigation_Previews: PreviewProvider {
//    static var previews: some View {
//        TagNavigation()
//    }
//}
