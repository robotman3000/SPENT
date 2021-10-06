//
//  MacHome.swift
//  macOS
//
//  Created by Eric Nims on 6/8/21.
//

import SwiftUI
import SwiftUIKit

struct HomeView: View {
    @StateObject private var context = SheetContext()
    @StateObject private var aContext = AlertContext()
    @State var selected: DBTransactionTemplate?
    @EnvironmentObject var store: DatabaseStore
    
    var body: some View {
        ScrollView {
            VStack{
                Section (header: Text("Shortcuts")){
                    HStack{
                        Spacer()
                        Button("New Transaction"){
                            aContext.present(AlertKeys.notImplemented)
                        }
                        Spacer()
                        Button("Reconcile with Statement"){
                            aContext.present(AlertKeys.notImplemented)
                        }
                        Spacer()
                        HStack {
                            QueryWrapperView(source: TemplateRequest()){ templateList in
                                Picker(selection: $selected, label: Text("Template: ")) {
                                    ForEach(templateList, id: \.id) { template in
                                        let templateData = try! template.decodeTemplate()
                                        if let templData = templateData {
                                            Text(templData.name).tag(template as DBTransactionTemplate?)
                                        }
                                    }
                                }
                            }
                            Button("New from template"){
                                if let dbtemplate = selected {
                                    let templateData = try! dbtemplate.decodeTemplate()
                                    if let templData = templateData {
                                        var transaction = templData.renderTransaction(date: Date())
                                        print(transaction)
                                        store.updateTransaction(&transaction,
                                                                onComplete: { context.dismiss() },
                                                                onError: { error in aContext.present(AlertKeys.databaseError(message: error.localizedDescription ))})
                                    }
                                } else {
                                    aContext.present(AlertKeys.message(message: "Select a template!"))
                                }
                            }
                        }
                        Spacer()
                    }
                }
                
                // Pinned accounts and buckets
                Section(header: Text("Favorites")){
                    QueryWrapperView(source: TagRequest(onlyFavorite: true)){ tags in
                        ForEach(tags) { tag in
                            Text(tag.name)
                        }
                    }
                    QueryWrapperView(source: BucketRequest(onlyFavorite: true)){ buckets in
                        ForEach(buckets) { bucket in
                            Text(bucket.name)
                        }
                    }
                }
            }
        }
        .navigationTitle("Summary")
        .alert(context: aContext)
        .sheet(context: context)
    }
}

struct MacHome_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
