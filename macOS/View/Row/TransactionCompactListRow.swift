//
//  TransactionCompactListRow.swift
//  macOS
//
//  Created by Eric Nims on 4/15/22.
//

import SwiftUI
import SwiftUIKit

struct TransactionCompactListRow: View {
    @Environment(\.colorScheme) var colorScheme
    let model: TransactionInfo
    var showRunning: Bool = false
    var showEntryDate: Bool = false
    
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
                }.frame(minWidth: 90, maxWidth: 90)
                
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
        }
    }
}

//struct TransactionListRow_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionListRow()
//    }
//}
