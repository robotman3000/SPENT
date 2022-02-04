//
//  FormModel.swift
//  macOS
//
//  Created by Eric Nims on 11/3/21.
//

import SwiftUI
import SwiftUIKit
import GRDB

protocol FormModel: ObservableObject {
    func loadState(withDatabase: Database) throws -> Void
    func validate() throws -> Void
    func submit(withDatabase: Database) throws -> Void
}

struct FormLifecycle<Model: FormModel>: ViewModifier {
    @Environment(\.dbQueue) var database
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
                      try database.write { db in
                          try model.submit(withDatabase: db)
                      }
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
              try database.read { db in
                  try model.loadState(withDatabase: db)
              }
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
