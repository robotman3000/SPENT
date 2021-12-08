//
//  Errors.swift
//  macOS
//
//  Created by Eric Nims on 11/4/21.
//

import Foundation

struct FormValidationError: Error, LocalizedError {
    let errorDescription: String?

    init(_ description: String) {
        errorDescription = description
    }
}

struct FormInitializeError: Error, LocalizedError {
    let errorDescription: String?

    init(_ description: String) {
        errorDescription = description
    }
}
