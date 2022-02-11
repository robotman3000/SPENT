//
//  BucketManagerView.swift
//  macOS
//
//  Created by Eric Nims on 2/10/22.
//

import SwiftUI
import SwiftUIKit
import GRDBQuery
import Combine

struct BucketManagerView: View {
    @Query(AllBuckets(), in: \.dbQueue) var buckets: [Bucket]
    @State var selected: Bucket? = nil as Bucket?
    @StateObject private var sheetContext = SheetContext()
    @StateObject private var aContext = AlertContext()
    
    var body: some View {
        VStack{
            VStack {
                HStack {
                    Button(action: {
                        sheetContext.present(FormKeys.bucket(context: sheetContext, bucket: nil))
                    }) {
                        Image(systemName: "plus")
                    }
                    Spacer()
                }
            }.padding()
            
            List(selection: $selected) {
                ForEach(buckets){ bucket in
                    Text(bucket.name).contextMenu { ContextMenu(sheet: sheetContext, forBucket: bucket) }.tag(bucket)
                }
            }
        }.sheet(context: sheetContext).alert(context: aContext)
    }
    
    private struct ContextMenu: View {
        @EnvironmentObject var databaseManager: DatabaseManager
        @ObservedObject var sheet: SheetContext
        let forBucket: Bucket
        
        var body: some View {
            Button("Edit bucket") {
                sheet.present(FormKeys.bucket(context: sheet, bucket: forBucket))
            }
            Button("Delete \(forBucket.name)") {
                databaseManager.action(.deleteBucket(forBucket), onSuccess: {
                    print("deleted bucket successfully")
                })
            }
        }
    }
}

struct BucketManagerView_Previews: PreviewProvider {
    static var previews: some View {
        BucketManagerView()
    }
}
