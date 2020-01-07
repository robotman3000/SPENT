# Roadmap:
- Implement new SQLIB database engine
- Backbone: Filtered Views
- Level 2 Transaction Filtering (Account selection)
- Finish Grouped Transactions
- Level 1 Transaction Filtering (jquery QueryBuilder)
- Transaction Tagging
- Filter by tags
- Sort by tags
- Eventually create UML (or similar) diagrams of code layout and design

# Major Feature Wishlist:

#### Core
- Implement an object based enum system
- Database Reconcile
- Database and Transaction Import/Export
- Spending Report Generation
- Automatic or Semi-Automatic Recurring Transactions
- Database cloud synchronization
- Feature to save level 1 filters by name and reuse them later
- Some sort of level 0 filtering (Simple table string search)

#### SPENT.js
- Table Merge-Dif interface
- Tag manager UI

# Bugs and Minor Features:
#### Core
- Replace the StatusMap table with a code based enum

#### SPENT.js
- The balance badges need to float-right
- The tree styles needs work
- Table Styles needs work
- Add a Database init wizard
- Fix sorting by "generated" columns
- Add an "apply" button to the transaction filter interface
- Transaction amounts should be sorted by display value not data value
- Vary modal sizes by screen size
- UI tooltips
- Batch editing of table rows
- Batch delete of table rows

#### AccountStatusView
- Balance text coloring

#### AccountTreeView
- The account tree view should become "responsive" at the same time as the rest of the ui
- Tags ahould align to the right
- Badge to show transaction status counts

#### Model Management
- Modifying one model type can cause changes in other model types. those changes are not handled correctly

#### Transaction Table > TableRowView
- The view needs to scale properly on small screens
- Value based row tinting (To show status)

#Design Issues / Notes:
- Virtual columns should perform value caching
Note: Implement vir col dependencies (A vir col can dep on [It's Row, Other rows in table, other rows in other table]). when a dep is changed mark col as dirty

- The server doesn't properly close the database / No proper way to shutdown the server

#General TODO:
- Verify dates are handled properly everywhere
- All icons should display properly









