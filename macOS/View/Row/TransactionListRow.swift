//
//  TransactionListRow.swift
//  SPENT
//
//  Created by Eric Nims on 10/16/21.
//

import SwiftUI
import SwiftUIKit

struct TransactionListRow: View {
    @Environment(\.colorScheme) var colorScheme
    let model: TransactionInfo
    var showRunning: Bool = false
    var showEntryDate: Bool = false
    var rowMode: TransactionRowMode = .full
    var enableHighlight: Bool = true

    var body: some View {
        VStack (alignment: .leading){
            Spacer()
            HStack(alignment: .center){
                //TODO: This should be split into two views
                Spacer(minLength: 2)
                model.transaction.status.getIconView().frame(width: 16, height: 16)
                
                // Payee or Type
                HStack{
                    Text(model.transaction.payee.isEmpty ? model.type.getStringName() : model.transaction.payee)
                    Spacer()
                }.frame(minWidth: 100, maxWidth: 150)
                    
                // Date
                HStack {
                    if !showEntryDate {
                        if let postDate = model.transaction.postDate  {
                            Text(postDate.transactionFormat)
                        } else {
                            Text(model.transaction.entryDate.transactionFormat)
                        }
                    } else {
                        Text(model.transaction.entryDate.transactionFormat)
                    }
                    Spacer()
                }.frame(minWidth: 95, maxWidth: 95)
                
                // Amount
                HStack {
                    Spacer()
                    Text(model.transaction.amount.currencyFormat).foregroundColor(model.transaction.amount < 0 ? .red : .gray)
                }.frame(minWidth: 80, maxWidth: 80)
                
                // Bucket
                HStack {
                    VStack{
                        HStack {
                            Text(model.bucket?.displayName ?? "No Bucket")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            //Image(systemName: model.contextType == .Withdrawal ? "arrow.left" : "arrow.right")
                            
                            Text(model.account.name)
                                .foregroundColor(.gray)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    Spacer()
                }.frame(minWidth: 80, maxWidth: .infinity)
                
                if rowMode == .compact {
                    TransactionTagsView(tags: model.tags)
                }
                
                // Running Balance
                if showRunning {
                    if let balance = model.runningBalance?.runningBalance {
                        HStack{
                            Spacer()
                            Text(balance.currencyFormat)
                        }.frame(minWidth: 70, maxWidth: 80)
                    }
                }
                
                if model.transaction.status.rawValue > Transaction.StatusTypes.Posting.rawValue && model.split == nil && model.transaction.postDate == nil {
                    Image(systemName: "exclamationmark.triangle").help("Post date is missing")
                }
                
                if model.split != nil && model.transaction.postDate != nil {
                    Image(systemName: "exclamationmark.triangle").help("Non-null post date")
                }
            }
            
            // Tags and Memo
            if rowMode == .full {
                HStack {
                    Text("").frame(width: 16)
                    Text(model.transaction.memo).help(model.transaction.memo)
                    Spacer()
                    TransactionTagsView(tags: model.tags)
                }
            }
            Spacer()
        }.listRowBackground(enableHighlight ? model.transaction.status.getHighlightColor() : nil)
    }
    
    private struct TransactionTagsView: View {
        let tags: [Tag]
        
        var body: some View {
            ForEach(tags, id: \.self){ tag in
                Text(tag.name).fontWeight(.bold).frame(minWidth: 50)
                    .font(.caption)
                    .padding(3)
                    .background(Color.gray)
                    .cornerRadius(50)
            }
        }
    }
}

//struct TransactionListRow_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionListRow()
//    }
//}
