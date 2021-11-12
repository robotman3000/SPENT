//
//  FormModel.swift
//  macOS
//
//  Created by Eric Nims on 11/3/21.
//

import SwiftUI
import SwiftUIKit

protocol FormModel: ObservableObject {
    func loadState(withDatabase: DatabaseStore) throws -> Void
    func validate() throws -> Void
    func submit(withDatabase: DatabaseStore) throws -> Void
}

struct FormLifecycle<Model: FormModel>: ViewModifier {
    @EnvironmentObject fileprivate var databaseStore: DatabaseStore
    @StateObject fileprivate var alertContext: AlertContext = AlertContext()
    @ObservedObject var model: Model
    
    let onSubmit: () -> Void
    let onCancel: () -> Void
    
    func body(content: Content) -> some View {
        content
        // Form Lifecycle
        .alert(context: alertContext)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
              Button("Cancel", action: {
                  onCancel()
              })
          }
          ToolbarItem(placement: .confirmationAction){
              Button("Done", action: {
                  do {
                      try model.validate()
                      try model.submit(withDatabase: databaseStore)
                      onSubmit()
                  } catch {
                      print(error)
                      alertContext.present(AlertKeys.message(message: error.localizedDescription))
                  }
              })
          }
        }.padding()
        .onAppear(perform: {
          do {
              try model.loadState(withDatabase: databaseStore)
          } catch {
              print(error)
          }
        })
    }
}

extension View {
    func formFooter<Model: FormModel>(_ model: Model, onSubmit: @escaping () -> Void, onCancel: @escaping () -> Void) -> some View {
        modifier(FormLifecycle(model: model, onSubmit: onSubmit, onCancel: onCancel))
  }
}
