//
//  TransactionView.swift
//  iOS
//
//  Created by Eric Nims on 7/3/21.
//

import SwiftUI

struct TransactionView: View {
    
    let data: TransactionData
    
    var body: some View {
        VStack{
            Text(data.transaction.memo)
        }.toolbar(content: {
            EditButton()
        })
    }
}

//struct TransactionView_Previews: PreviewProvider {
//    static var previews: some View {
//        let bucket1 = Bucket(id: 1, name: "Account 1", parentID: nil, ancestorID: nil, memo: "", budgetID: nil)
//        let bucket2 = Bucket(id: 1, name: "Account 2", parentID: nil, ancestorID: nil, memo: "", budgetID: nil)
//
//        let t = Transaction.getRandomTransaction(withID: 1, withSource: bucket1.id, withDestination: bucket2.id, withGroup: nil)
//        TransactionView()
//    }
//}
