//
//  TransactionSplitTable.swift
//  macOS
//
//  Created by Eric Nims on 7/29/21.
//

import SwiftUI
import SwiftUIKit

//struct SplitTransactionMemberList: View {
//    let ids: [Int64]
//    //@State var selected: Transaction?
//
//    var body: some View {
//        List(/*selection: $selected*/) {
//            if ids.isEmpty {
//                Text("No Items")
//            }
//
//            ForEach(ids, id: \.self){ memberID in
//                SplitTransactionMemberListRow(forID: memberID)
//            }
//        }
////        .popover(item: $selected) { transaction in
////            SplitMemberForm(model: SplitMemberFormModel(member: transaction), onSubmit: {}, onDelete: {}, onCancel: {})
////        }
//    }
//}

//struct SplitTransactionMemberListRow: View {
//    @EnvironmentObject var store: DatabaseStore
//    let forID: Int64
//
//    var body: some View {
//        AsyncContentView(source: TransactionFilter.publisher(store.getReader(), forID: forID)){ model in
//            Internal_SplitTransactionMemberListRow(model: model)
//        }
//    }
//}

struct Internal_SplitTransactionMemberListRow: View {
    let model: SplitMemberModel
    
    var body: some View {
        HStack(alignment: .center){
            VStack (alignment: .leading) {
                HStack{
                    Text("\(model.bucket?.name ?? "NIL")")
                    Spacer()
                }
                HStack{
                    // TODO: Properly format the currency value
                    Text("$\(model.amount)").bold()
                    Spacer()
                }
            }.frame(width: 150)
            Text(model.memo).help(model.memo)
            Spacer()
        }
    }
}

//struct TransactionSplitTable_Previews: PreviewProvider {
//    static var previews: some View {
//        //TransactionSplitTable()
//        SplitTransactionMemberList.Row(bucketName: "Preview Bucket", amount: 3756, memo: "Some relevant memo goes here")
//    }
//}
