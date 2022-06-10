//
//  FormKeys.swift
//  iOS
//
//  Created by Eric Nims on 6/8/22.
//

import SwiftUI
import SwiftUIKit

enum FormKeys: SheetProvider {
    case account(context: SheetContext, account: Account?)
    case transaction(context: SheetContext, transaction: Transaction?)
    
    var sheet: AnyView {
        NavigationView {
            switch self {
            case let .account(context: context, account: account):
                AccountForm(model: AccountFormModel(account ?? Account(name: "")),
                                    onSubmit: { context.dismiss() }, onCancel: { context.dismiss() })
                .navigationTitle("Edit Account")
            case let .transaction(context: context, transaction: transaction):
                TransactionForm(model: TransactionFormModel(transaction:
                transaction ?? Transaction(id: nil, status: .Uninitiated, amount: 0, payee: "", memo: "", entryDate: Date(), postDate: nil, bucketID: nil, accountID: -1)),
                                    onSubmit: { context.dismiss() }, onCancel: { context.dismiss() })
            }
        }.any()
    }
}
