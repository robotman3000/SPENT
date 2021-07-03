//
//  ViewModel.swift
//  SPENT
//
//  Created by Eric Nims on 7/2/21.
//

import Foundation

protocol ViewModel {
    func load(_ db: AppDatabase) -> Void
}
