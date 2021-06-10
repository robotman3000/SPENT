//
//  BaseForm.swift
//  macOS
//
//  Created by Eric Nims on 6/8/21.
//

import Foundation

protocol BaseForm {
    var title: String { get }
    
    func onSubmit(_ data: inout Tag) -> Void
    func onCancel() -> Void
}
