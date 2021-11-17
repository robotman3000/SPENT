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
            Internal_TransactionListRow(model: model, showTags: appState.showTags, showMemo: appState.showMemo, showRunning: appState.sorting == .byDate)
        }
    }
}

struct Internal_TransactionListRow: View {
    @Environment(\.colorScheme) var colorScheme
    let model: TransactionModel
    var showTags: Bool = true
    var showMemo: Bool = true
    var showRunning: Bool = true
    
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
                    if let splitMember = model.splitMember {
                        Text(splitMember.amount.currencyFormat).foregroundColor(model.splitType == .Withdrawal ? .red : .gray)
                    } else {
                        if let bal = model.balance {
                            Text(bal.amount.currencyFormat).foregroundColor(model.contextType == .Withdrawal ? .red : .gray)
                        } else {
                            Text(model.transaction.amount.currencyFormat).foregroundColor(.black)
                        }
                    }
                    
                }.frame(minWidth: 80, maxWidth: 80)
                
                // Bucket
                HStack {
                    if model.splitMember != nil {
                        if let bal = model.balance {
                            Text("(\(bal.amount.currencyFormat))").foregroundColor(model.splitType == .Withdrawal ? .red : .gray)
                        } else {
                            Text("Balance Error")
                        }
                    }
                    VStack{
                        if model.transaction.group == nil {
                            let sName = model.source?.name ?? "NIL"
                            let dName = model.destination?.name ?? "NIL"
                            
                            HStack {
                                if model.transaction.type == .Transfer {
                                    Text(model.contextType == .Deposit ? sName : dName)
                                        .foregroundColor(.gray)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                Image(systemName: model.transaction.type == .Withdrawal ? "arrow.left" : "arrow.right")
                                
                                Text(model.transaction.type == .Deposit ? dName : sName)
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        } else {
                            Text("Split \(model.splitType.getStringName())")
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
