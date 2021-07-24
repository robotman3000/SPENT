//
//  MacHome.swift
//  macOS
//
//  Created by Eric Nims on 6/8/21.
//

import SwiftUI
import Foundation
import AppKit
import SwiftUI

struct MacHome: View {
    @State var filename = "Filename"
    @State var showFileChooser = false
    
    var body: some View {
        VStack{
            Text("Welcome to SPENT!")
//            ScrollView {
//                TestNSTable()//.background(Color.black)
//            }
        }
    }
}

struct MacHome_Previews: PreviewProvider {
    static var previews: some View {
        MacHome()
    }
}

class TableView: NSView {
    //var scrollViewTableView = NSScrollView()
    
    let tableView: NSTableView
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame frameRect: NSRect) {
        tableView = NSTableView(frame: .zero)
        tableView.rowSizeStyle = .large
        tableView.backgroundColor = .white
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.style = .fullWidth
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "column"))
        //NSHostingView(rootView: Text(""))
        tableView.headerView = NSTableHeaderView()
        column.width = 1
        tableView.addTableColumn(column)
        
        super.init(frame: frameRect)
        
        
        
        // Add subviews
        //scrollViewTableView.documentView = tableView
        [tableView].forEach(addSubview)
        
        // Add constraints
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([tableView.topAnchor.constraint(equalTo: tableView.superview!.topAnchor),
                                     tableView.leadingAnchor.constraint(equalTo: tableView.superview!.leadingAnchor),
                                     tableView.trailingAnchor.constraint(equalTo: tableView.superview!.trailingAnchor),
                                     tableView.bottomAnchor.constraint(equalTo: tableView.superview!.bottomAnchor)
                                    ])
    }
    
    
}

class TableViewController: NSViewController {
    var mainView: TableView { return self.view as! TableView }
    fileprivate var adapter: AdapterTableView?
    
    // MARK: View Controller
    
    override func loadView() {
        //let rect = NSRect(x: 0, y: 0, width: 200, height: 200)
        view = TableView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Configure Table view
        adapter = AdapterTableView(tableView: mainView.tableView)
        let users = [User(name: "Alberto"),
                     User(name: "Felipe"),
                     User(name: "Aaron"),
                     User(name: "Laura"),
                     User(name: "Felipe"),
                     User(name: "Aaron"),
                     User(name: "Laura"),
                     User(name: "Felipe"),
                     User(name: "Aaron"),
                     User(name: "Laura"), User(name: "Felipe"),
                     User(name: "Aaron"),
                     User(name: "Laura"), User(name: "Felipe"),
                     User(name: "Aaron"),
                     User(name: "Laura"), User(name: "Felipe"),
                     User(name: "Aaron"),
                     User(name: "Laura"),
                     User(name: "Felipe"),
                     User(name: "Aaron"),
                     User(name: "Laura"),
                     User(name: "Giuseppe")]
        adapter?.add(items: users)
    }
}

class AdapterTableView: NSObject {
    fileprivate static let column = "column"
    fileprivate static let heightOfRow: CGFloat = 26
    
    fileprivate var items: [User] = [User]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    private var tableView: NSTableView
    
    init(tableView: NSTableView) {
        self.tableView = tableView
        super.init()
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }
        
    func add(items: [User]) {
        self.items += items
    }
}

extension AdapterTableView: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard (tableColumn?.identifier)!.rawValue == AdapterTableView.column else { fatalError("AdapterTableView identifier not found") }
        
        let name = items[row].name
        let view = NSTextField(string: name)
        view.isEditable = false
        view.isBordered = false
        view.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return AdapterTableView.heightOfRow
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true
    }
}

struct User {
    let name: String
}

struct TestNSTable: NSViewControllerRepresentable {
    typealias NSViewControllerType = TableViewController

    func makeNSViewController(context: NSViewControllerRepresentableContext<TestNSTable>) -> TableViewController {
        return TableViewController()
    }

    func updateNSViewController(_ nsViewController: TableViewController, context: NSViewControllerRepresentableContext<TestNSTable>) {

    }

}
