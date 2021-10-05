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
