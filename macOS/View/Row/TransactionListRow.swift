//
//  TransactionListRow.swift
//  SPENT
//
//  Created by Eric Nims on 10/16/21.
//

import SwiftUI

struct TransactionListRow: View {
    @EnvironmentObject var appState: GlobalState
    @EnvironmentObject var store: DatabaseStore
    let forID: Int64
    
    var body: some View {
        AsyncContentView(source: TransactionFilter.publisher(store.getReader(), forID: forID)) { model in
            Internal_TransactionListRow(model: model, showTags: appState.showTags, showMemo: appState.showMemo)
        }
    }
}

struct Internal_TransactionListRow: View {
    @Environment(\.colorScheme) var colorScheme
    @State var model: TransactionModel
    @State var showTags: Bool = true
    @State var showMemo: Bool = true
    @State var showRunning: Bool = true
    
    var body: some View {
        VStack (alignment: .leading){
            Spacer()
            HStack(alignment: .center){
                //TODO: This should be split into two views
                Spacer(minLength: 2)
                model.transaction.status.getIconView().frame(width: 16, height: 16)
                
                // Payee or Type
                HStack{
                    Text(model.balance == nil ? "Allocation" : model.transaction.payee ?? model.transaction.type.getStringName())
                    Spacer()
                }.frame(minWidth: 100, maxWidth: 150)
                    
                // Date
                HStack {
                    if let bal = model.balance  {
                        Text(bal.date.transactionFormat)
                    } else {
                        Text("")
                    }
                    Spacer()
                }.frame(minWidth: 90, maxWidth: 90)
                
                // Amount
                HStack {
                    Spacer()
                    //Text(bal.amount.currencyFormat)
                    //if let trans = td.splitMember {
                    //    Text(trans.amount.currencyFormat).foregroundColor(td.splitType == .Withdrawal ? .red : .gray)
                    //} else {
                    //    Text(td.amountFormatted).foregroundColor(td.contextType == .Withdrawal ? .red : .gray)
                    //}
                    
                }.frame(minWidth: 80, maxWidth: 80)
                
                // Bucket
                HStack {
//                    if td.splitMember != nil {
//                        Text("(\(td.amountFormatted))").foregroundColor(td.splitType == .Withdrawal ? .red : .gray)
//                    }
                    VStack{
                        if model.transaction.group == nil {
                            let sName = model.source?.name ?? "NIL"
                            let dName = model.destination?.name ?? "NIL"
                            
                            HStack {
//                                if model.transaction.type == .Transfer {
//                                    Text(td.contextType == .Deposit ? sName : dName)
//                                        .foregroundColor(.gray)
//                                        .font(.subheadline)
//                                        .fontWeight(.medium)
//                                }
                                
                                Image(systemName: model.transaction.type == .Withdrawal ? "arrow.left" : "arrow.right")
                                
                                Text(model.transaction.type == .Deposit ? dName : sName)
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        } else {
                            //Text("Split \(td.splitType.getStringName())")
                            Text("Split")
                        }
                    }
                    Spacer()
                }.frame(minWidth: 80, maxWidth: .infinity)
                
                // Running Balance
                if showRunning {
                    HStack{
                        Spacer()
                        if let bal = model.balance {
                            Text((bal.postedRunning ?? -1).currencyFormat)
                        } else {
                            Text("")
                        }
                    }.frame(minWidth: 70, maxWidth: 80)
                }
                
            }
            
            // Tags and Memo
            if showMemo || showTags {
                HStack {
                    Text("").frame(width: 16)
                    if showMemo {
                        Text(model.transaction.memo).help(model.transaction.memo)
                    }
                    Spacer()
                    if showTags {
                        ForEach(model.tags, id: \.self){ tag in
                            Text(tag.name).fontWeight(.bold).frame(minWidth: 50)
                                .font(.caption)
                                .padding(3)
                                .background(Color.gray)
                                .cornerRadius(50)
                        }
                    }
                }
            }
//
//                Spacer(minLength: 5)

//
//            Divider().frame(height: 5)
            Spacer()
        }
    }
}

//struct TransactionListRow_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionListRow()
//    }
//}
