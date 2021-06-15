//
//  TagNavigation.swift
//  macOS
//
//  Created by Eric Nims on 6/8/21.
//

import SwiftUI

struct TagNavigation: View, SidebarNavigable {
        
    @EnvironmentObject var stateController: StateController
    @State var selectedTag: Tag?
    @Query(TagRequest()) var tags: [Tag]
    @State private var showingAlert = false
    @State private var showingForm = false

    var body: some View {
        List(selection: $selectedTag) {
            Section(header: Text("Tags")){
                ForEach(Array(tags.enumerated()), id: \.element) { index, tag in
                    NavigationLink(destination: ListTransactionsView(query: TransactionRequest(tag), title: tag.name)) {
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
            do {
                try stateController.database.deleteTag(id: selectedTag!.id!)
                selectedTag = nil
            } catch {
                showingAlert.toggle()
            }
        }
        .sheet(isPresented: $showingForm) {
            TagForm(title: "Edit Tag", tag: selectedTag!, onSubmit: onSubmitTag, onCancel: {showingForm.toggle()})
            .padding()
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Database Error"),
                message: Text("Failed to delete tag"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    func onSubmitTag(_ tag: inout Tag) {
        do {
            try stateController.database.saveTag(&tag)
            showingForm.toggle()
        } catch {
            showingAlert.toggle()
        }
    }
    
}

//struct TagNavigation_Previews: PreviewProvider {
//    static var previews: some View {
//        TagNavigation()
//    }
//}
