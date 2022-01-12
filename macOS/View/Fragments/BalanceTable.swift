//
//  BalanceTable.swift
//  SPENT
//
//  Created by Eric Nims on 4/22/21.
//

import SwiftUI
import GRDB

struct BalanceTable: View {
    @EnvironmentObject var store: DatabaseStore
    let forID: Int64?
    
    var body: some View {
        if forID != nil && forID! > -1 {
            AsyncContentView(source: BucketFilter.publisher(store.getReader(), forID: forID!), "BalanceTable") { model in
                Internal_BalanceTable(model: model)
            }
        } else {
            Internal_BalanceTable(model: nil)
        }
    }
    
    struct BalanceView: View {
        
        let text: String
        let balance: Int?
        
        var body: some View {
            VStack (alignment: .leading){
                HStack(){
                    Text(text)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    Spacer()
                }
                HStack(){
                    Spacer()
                    CurrencyText(amount: balance).frame(alignment: .trailing)
                }
            }.frame(width: 100, height: 30, alignment: .center)
            .padding()
            .background(Color.black.opacity(0.1))
            //.border(Color.black)
            //.cornerRadius(20)
            .clipShape(Rectangle()).cornerRadius(15)
        }
    }
}

private struct Internal_BalanceTable: View {
    let model: BucketModel?
    
    var body: some View {
        VStack (spacing: 15){
            HStack (spacing: 3){
                Text("Balance of")
                Text(model?.bucket.name ?? "nothing").fontWeight(.bold)
            }
            HStack (spacing: 15) {
                BalanceTable.BalanceView(text: "Posted", balance: model?.balance?.posted)
                BalanceTable.BalanceView(text: "Available", balance: model?.balance?.available)
            }
            HStack (spacing: 15) {
                BalanceTable.BalanceView(text: "Posted in Tree", balance: model?.balance?.postedTree)
                BalanceTable.BalanceView(text: "Available in Tree", balance: model?.balance?.availableTree)
            }
        }.padding()
    }
}

//struct BalanceTable_Previews: PreviewProvider {
//    static var previews: some View {
//        BalanceTable(name: "Preview Test", posted: 10043, available: -3923, postedInTree: -38934, availableInTree: 20482)
//    }
//}
