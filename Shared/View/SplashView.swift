//
//  SplashView.swift
//  SPENT
//
//  Created by Eric Nims on 4/14/21.
//

import SwiftUI

struct SplashView: View {
    
    var showLoading: Bool
    
    var body: some View {
        VStack {
            Text("SPENT").font(Font.largeTitle)
            Text("The Simple Expense Tracker").font(Font.body)
            
            if showLoading {
                ProgressView()
                       // and if you want to be explicit / future-proof...
                       // .progressViewStyle(CircularProgressViewStyle())
            }
        }
    }
}

/*struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}*/
