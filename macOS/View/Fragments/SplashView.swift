//
//  SplashView.swift
//  SPENT
//
//  Created by Eric Nims on 4/14/21.
//

import SwiftUI

struct SplashView: View {
    
    var showLoading: Bool = false
    var loadDatabase: (_ path: URL, _ isNew: Bool) -> Void = {_,_ in}
    
    var body: some View {
        VStack {
            Text("SPENT").font(Font.largeTitle)
            Text("The Simple Expense Tracker").font(Font.body)
            
            if showLoading {
                ProgressView().progressViewStyle(CircularProgressViewStyle())
            } else {
                VStack {
                    HStack{
                        Button("New Database"){
                            newDBAction()
                        }
                        Button("Open Database"){
                            openDBAction()
                        }
                    }
                    
                    Button("Quit"){
                        exit(0)
                    }
                }.padding()
            }
        }
    }
    
    func newDBAction(){
        saveFile(allowedTypes: [.spentDatabase], onConfirm: {url in
            if url.startAccessingSecurityScopedResource() {
                defer {
                    url.stopAccessingSecurityScopedResource() }
                if !FileManager.default.fileExists(atPath: url.path) {
                    do {
                        try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
                loadDatabase(url, true)
            }
        }, onCancel: {})
    }
    
    func openDBAction(){
        openFile(allowedTypes: [.spentDatabase], onConfirm: { selectedFile in
            loadDatabase(selectedFile, false)
        }, onCancel: {})
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView(showLoading: true, loadDatabase: {_,_  in})
        SplashView(showLoading: false, loadDatabase: {_,_  in})
    }
}
