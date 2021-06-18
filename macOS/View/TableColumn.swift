//
//  TableColumn.swift
//  SPENT
//
//  Created by Eric Nims on 6/18/21.
//

import SwiftUI

struct TableColumn<Header: View, Body: View, Footer: View> {
    let header: Header
    let body: Body
    let footer: Footer

    init(@ViewBuilder header: () -> Header, @ViewBuilder body: () -> Body, @ViewBuilder footer: () -> Footer) {
        self.header = header()
        self.body = body()
        self.footer = footer()
    }
}
