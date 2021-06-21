//
//  DatabaseManagerView.swift
//  SPENT
//
//  Created by Eric Nims on 6/18/21.
//

import SwiftUI

struct DatabaseManagerView: View {
    
    let onCancel: () -> Void
    
    var body: some View {
        VStack{
            TabView {
                BucketTable().tabItem {
                    Label("Accounts", systemImage: "folder")
                }
             
                ScheduleTable().tabItem {
                    Label("Schedules", systemImage: "calendar.badge.clock")
                }
         
                TagTable().tabItem {
                    Label("Tags", systemImage: "tag")
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
