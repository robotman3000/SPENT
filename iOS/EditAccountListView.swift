//
//  EditAccountListView.swift
//  iOS
//
//  Created by Eric Nims on 7/8/21.
//

import SwiftUI

struct EditAccountListView: View {
    @EnvironmentObject var store: DatabaseStore
    @State var selected: Bucket?
    
    var body: some View {
        List(selection: $selected){
            ForEach(store.buckets, id: \.self){ bucket in
                HStack{
                    Text(bucket.name).frame(maxWidth: .infinity)
                }.tag(bucket).background(Color.black.opacity(0)).onTapGesture {
                    selected = bucket
                }
            }.onDelete(perform: {_ in})
        }.sheet(item: $selected) { bucket in
            Text(bucket.name)
        }
    }
}

struct EditAccountListView_Previews: PreviewProvider {
    static var previews: some View {
        EditAccountListView()
    }
}
