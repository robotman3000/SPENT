from SPENT import SQLIB as sqlib
from SPENT import LOGGER as log
from SPENT import SPENT_Schema as schema

logman = log.getLogger("Main")

class SPENTDB:
    def __init__(self):
        # Represents an instance of the schema; there is one sqlib.Database instance per sqlite db file
        self.database = sqlib.Database("SPENT-SQLIB.db")

    def testExecute(self):
        logman.info("Execute Test")
        # Represents access to the database; All db io uses this
        connection1 = self.database.getConnection("Master")
        connection2 = self.database.getConnection("Secondary")

        connection1.connect()
        connection2.connect()

        result = connection1.execute("SELECT * FROM Tags") # This is dangerous
        result = connection1.execute("SELECT * FROM Buckets")  # This is dangerous
        result = connection2.execute("SELECT * FROM Transactions")  # This is dangerous
        result = connection2.execute("SELECT * FROM TransactionTags")  # This is dangerous
        result = connection2.execute("SELECT * FROM TransactionGroups")  # This is dangerous

        logman.info("Query Result: %s" % result)

        connection1.disconnect()
        connection2.disconnect()

        result = connection2.execute("SELECT * FROM TransactionGroups")  # This is dangerous
        result = connection1.execute("SELECT * FROM Buckets")  # This is dangerous

    def testAPI(self):
        logman.info("Execute API Test")
        connection3 = self.database.getConnection("API-Test")

        connection3.connect()

        #TODO: Query Filters
        filter = None # Unimplemented
        someID = 54
        someIDs = [4, 6, 56, 23, 29]

        # Get By ID
        row = schema.EnumTransactionTable.getRow(connection3, someID)
        logman.info("Row Type: %s" % type(row))
        logman.info("getRow() returned Row: %s" % row)
        #amount = row[TransactionsTable.Amount] #TODO: Implement this shorthand
        logman.info("Row Amount: %s" % row.getValue(schema.EnumTransactionTable.Amount))
        logman.info("Alt Row Amount: %s" % row.getAmount())
        newAmount = 100000000
        #row[TransactionsTable.Amount] = newAmount #TODO: Implement this shorthand
        row.setValue(schema.EnumTransactionTable.Amount, newAmount)
        logman.info("New Row Amount: %s" % row.getValue(schema.EnumTransactionTable.Amount))

        schema.EnumTransactionTable.deleteRow(connection3, someID)

        newRow = {schema.EnumTransactionTable.Amount: 300.45, schema.EnumTransactionTable.Memo: "A test transaction"}
        returnValue = schema.EnumTransactionTable.createRow(connection3, newRow)
        # returnValue will either be the ID of the new row or the new row itself

        # Get Selection
        rowSelection = schema.EnumTransactionTable.select(connection3, filter)

        #OR

        # Get BY ID's; This returns a RowSelection
        rows = schema.EnumTransactionTable.getRows(connection3, someIDs)

        #amounts = rows[TransactionsTable.Amount] #TODO: Implement this shorthand
        amounts = rows.getValues(schema.EnumTransactionTable.Amount)
        #rows[TransactionsTable.Amount] = newAmount #TODO: Implement this shorthand
        rows.setValues(schema.EnumTransactionTable.Amount, newAmount)

        rows.deleteRows()

logman.debug("Test Message")
spentdb = SPENTDB()
spentdb.testExecute()
spentdb.testAPI()