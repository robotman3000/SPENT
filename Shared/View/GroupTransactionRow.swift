//
//  GroupTransactionRow.swift
//  SPENT
//
//  Created by Eric Nims on 7/1/21.
//

import SwiftUI

struct GroupTransactionRow: View {
    
    @Query<TransactionRequest> var transactions: [Transaction]
    @State var bucket: Bucket
    
    init(_ groupID: UUID, bucket: Bucket){
        self._transactions = Query(TransactionRequest(groupID))
        self.bucket = bucket
    }
    
    var body: some View {
        ForEach(transactions){ item in
            TransactionRow(transaction: item, bucket: bucket)
        }
    }
}

//struct GroupTransactionRow_Previews: PreviewProvider {
//    static var previews: some View {
//        GroupTransactionRow()
//    }
//}
