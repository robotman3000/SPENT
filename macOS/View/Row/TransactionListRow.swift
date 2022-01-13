//
//  TransactionListRow.swift
//  SPENT
//
//  Created by Eric Nims on 10/16/21.
//

import SwiftUI
import SwiftUIKit

struct TransactionListRow: View {
    @EnvironmentObject var appState: GlobalState
    @EnvironmentObject var store: DatabaseStore
    
    let forID: Int64
    let forBucket: Int64?
    let isAccount: Bool
    
    var body: some View {
        AsyncContentView(source: TransactionFilter.publisher(store.getReader(), forRequest: TransactionRequest(forID: forID, viewingBucket: forBucket)), "TransactionListRow") { model in
            if model.transaction.type == .Split_Head {
                Internal_SplitListRow(model: model, showMemberAmount: !isAccount)
            } else {
                let shouldShowRunning = (appState.sorting == .byDate && isAccount)
                Internal_TransactionListRow(model: model, showTags: $appState.showTags, showMemo: $appState.showMemo, showRunning: shouldShowRunning)
            }
        }
    }
}

struct Internal_TransactionListRow: View {
    @Environment(\.colorScheme) var colorScheme
    let model: TransactionModel
    @Binding var showTags: Bool
    @Binding var showMemo: Bool
    let showRunning: Bool
    
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
                    if let display = model.display  {
                        Text(display.date.transactionFormat)
                    } else {
                        Text(model.transaction.date.transactionFormat)
                    }
                    Spacer()
                }.frame(minWidth: 90, maxWidth: 90)
                
                // Amount
                HStack {
                    Spacer()
                    let amount = model.display != nil ? model.display!.amount.currencyFormat : model.transaction.amount.currencyFormat
                    Text(amount).foregroundColor(model.contextType == .Withdrawal ? .red : .gray)
                }.frame(minWidth: 80, maxWidth: 80)
                
                // Bucket
                HStack {
                    VStack{
                        let sName = model.source?.name ?? "NIL"
                        let dName = model.destination?.name ?? "NIL"
                        
                        HStack {
                            if model.transaction.type == .Transfer {
                                Text(model.contextType == .Deposit ? sName : dName)
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            Image(systemName: model.contextType == .Withdrawal ? "arrow.left" : "arrow.right")
                            
                            Text(model.contextType == .Deposit ? dName : sName)
                                .foregroundColor(.gray)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    Spacer()
                }.frame(minWidth: 80, maxWidth: .infinity)
                
                // Running Balance
                if showRunning {
                    HStack{
                        Spacer()
                        if let bal = model.display {
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
            Spacer()
        }
    }
}

struct Internal_SplitListRow: View {
    let model: TransactionModel
    let showMemberAmount: Bool
    
    var body: some View {
        HStack {
            Text("Split \(model.splitType.getStringName())")
            
            if let splitMember = model.splitMember {
                if showMemberAmount {
                    Text(splitMember.amount.currencyFormat).foregroundColor(model.splitType == .Withdrawal ? .red : .gray)
                }
            }
            
            Text("(\(model.splitAmount.currencyFormat))").foregroundColor(model.splitType == .Withdrawal ? .red : .gray)
        }
    }
}
//struct TransactionListRow_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionListRow()
//    }
//}
