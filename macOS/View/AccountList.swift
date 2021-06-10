//
//  AccountList.swift
//  macOS
//
//  Created by Eric Nims on 4/30/21.
//

import SwiftUI

struct AccountList: View {
    
    var accounts: [Account]
    
    var body: some View {
        List{
            ForEach(accounts){ account in
                NavigationLink(destination: TransactionList(transactions: account.transactions)) {
                    AccountList.AccountRow(account: account)
                }
            }
        }.navigationTitle("Accounts")
    }
}

extension AccountList {
    struct AccountRow: View {
        
        var account: Account
        
        var body: some View {
            BaseRow(container: account)
        }
    }
    struct BucketRow: View {
        
        var bucket: Bucket
        
        var body: some View {
            BaseRow(container: bucket)
        }
    }
    private struct BaseRow: View {
        
        var container: TransactionContainer
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4.0) {
                HStack {
                    Text(container.name)
                        .font(.headline)
                    Spacer()
                    Text(container.balance.currencyFormat)
                        .font(.headline)
                }
            }
            .padding(.vertical, 8.0)
        }
    }
}
//struct AccountList_Previews: PreviewProvider {
//    static var previews: some View {
//        AccountList(accounts: Tests.testData.accounts)
//    }
//}
