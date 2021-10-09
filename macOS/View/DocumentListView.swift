//
//  DocumentListView.swift
//  macOS
//
//  Created by Eric Nims on 10/7/21.
//

import SwiftUI

struct DocumentListView: View {
    var transaction: Transaction
    
    var body: some View {
        QueryWrapperView(source: AttachmentRequest(transaction)){ attachments in
            if attachments.count > 0 {
                List(){
                    ForEach(attachments){ attachment in
                        Text(attachment.filename)
                    }
                }
            } else {
                Text("No Attachments Found")
            }
        }.frame(minWidth: 250, minHeight: 300)
    }
}

//struct DocumentListView_Previews: PreviewProvider {
//    static var previews: some View {
//        DocumentListView()
//    }
//}
