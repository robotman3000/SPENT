//
//  SPENTApp.swift
//  SPENT
//
//  Created by Eric Nims on 3/30/21.
//

import SwiftUI

struct Data {
    var transactions: [Transactions]
}

@main
struct SPENTiOSApp: App {
    @State
    var isActive: Bool = false
    
    var body: some Scene {
        WindowGroup {
            if isActive {
                TransactionList(transactions: loadData())
            } else {
                SplashView(showLoading: true).onAppear(){
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isActive = true
                    }
                }
            }
        }
    }
}
