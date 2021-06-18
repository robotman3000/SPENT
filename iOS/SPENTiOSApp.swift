//
//  SPENTApp.swift
//  SPENT
//
//  Created by Eric Nims on 3/30/21.
//

import SwiftUI

@main
struct SPENTiOSApp: App {
    @State var isActive: Bool = false
    @State var database: AppDatabase
    
    init() {
        do {
            database = try AppDatabase(path: getDBURL())
        } catch {
            print(error)
            database = AppDatabase()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if isActive {
                TransactionList().environment(\.appDatabase, database)
            } else {
                SplashView(showLoading: true).onAppear(){
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        isActive = true
                    }
                }
            }
        }
    }
}

struct TransactionList: View {
    @Query(TransactionRequest(true)) var transactions: [Transaction]
    
    var body: some View {
        if !transactions.isEmpty {
            List(transactions){ transaction in
                TransactionRow(transaction: transaction)
            }
        } else {
            Text("No Transactions Found")
        }
    }
}
