from SPENT import SQLIB as sqlib

TABLE_Tags = "Tags"
TABLE_Buckets = "Buckets"
TABLE_Transactions = "Transactions"
TABLE_TransactionTags = "TransactionTags"
TABLE_TransactionGroups = "TransactionGroups"

# TODO: Map out which names are for which table
COLUMN_ANY = "*"
COLUMN_ID = "ID"  # All Tables
COLUMN_Name = "Name"
COLUMN_Status = "Status"
COLUMN_Amount = "Amount"
COLUMN_TransDate = "TransDate"
COLUMN_PostDate = "PostDate"
COLUMN_SourceBucket = "SourceBucket"
COLUMN_DestBucket = "DestBucket"
COLUMN_Payee = "Payee"
COLUMN_GroupID = "GroupID"
COLUMN_Parent = "Parent"
COLUMN_Ancestor = "Ancestor"
COLUMN_Memo = "Memo"
COLUMN_TransactionID = "TransactionID"
COLUMN_TagID = "TagID"
COLUMN_Bucket = "Bucket"

class SPENTDB:
    def __init__(self):
        self.databaseSchema = sqlib.DatabaseSchema(1, [
            {"table": TABLE_Tags, "columns": [
            {"name": "ID", "type": "INTEGER", "PreventNull": True, "IsPrimaryKey": True,
             "AutoIncrement": True, "KeepUnique": True},
            {"name": "Name", "type": "TEXT", "PreventNull": True, "IsPrimaryKey": False,
             "AutoIncrement": False, "KeepUnique": True}]},
            {"table": TABLE_Buckets, "columns": [
            {"name": "ID", "type": "INTEGER", "PreventNull": True, "IsPrimaryKey": True, "AutoIncrement": True,
             "KeepUnique": True},
            {"name": "Name", "type": "TEXT", "PreventNull": True, "IsPrimaryKey": False, "AutoIncrement": False,
             "KeepUnique": True},
            {"name": "Parent", "type": "INTEGER", "remapKey": "Buckets:ID:Name", "PreventNull": True,
             "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False},
            {"name": "Ancestor", "type": "INTEGER", "remapKey": "Buckets:ID:Name", "PreventNull": True,
             "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False}]},
            {"table": TABLE_Transactions, "columns": [
            {"name": "ID", "type": "INTEGER", "PreventNull": True, "IsPrimaryKey": True, "AutoIncrement": True,
             "KeepUnique": True},
            {"name": "Status", "type": "INTEGER", "remapKey": "StatusMap:ID:Name",
             "PreventNull": True, "IsPrimaryKey": False, "AutoIncrement": False,
             "KeepUnique": False},
            {"name": "TransDate", "type": "INTEGER", "PreventNull": True,
             "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False},
            {"name": "PostDate", "type": "INTEGER", "PreventNull": False,
             "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False},
            {"name": "Amount", "type": "INTEGER", "PreventNull": True,
             "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False},
            {"name": "SourceBucket", "type": "INTEGER", "remapKey": "Buckets:ID:Name",
             "PreventNull": True, "IsPrimaryKey": False, "AutoIncrement": False,
             "KeepUnique": False},
            {"name": "DestBucket", "type": "INTEGER", "remapKey": "Buckets:ID:Name",
             "PreventNull": True, "IsPrimaryKey": False, "AutoIncrement": False,
             "KeepUnique": False},
            {"name": "Memo", "type": "TEXT", "PreventNull": False, "IsPrimaryKey": False,
             "AutoIncrement": False, "KeepUnique": False},
            {"name": "Payee", "type": "TEXT", "PreventNull": False, "IsPrimaryKey": False,
             "AutoIncrement": False, "KeepUnique": False},
            {"name": "GroupID", "type": "INTEGER", "PreventNull": True,
             "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False}]},
            {"table": TABLE_TransactionTags, "columns": [
            {"name": "TransactionID", "type": "INTEGER", "PreventNull": True, "IsPrimaryKey": False,
             "AutoIncrement": False, "KeepUnique": False},
            {"name": "TagID", "type": "INTEGER", "PreventNull": True, "IsPrimaryKey": False,
             "AutoIncrement": False, "KeepUnique": False},
            {"isConstraint": True, "constraintValue": "unq UNIQUE (TransactionID, TagID)"}]},
            {"table": TABLE_TransactionGroups, "columns": [
            {"name": "ID", "type": "INTEGER", "PreventNull": True, "IsPrimaryKey": True,
             "AutoIncrement": True, "KeepUnique": True},
            {"name": "Memo", "type": "TEXT", "PreventNull": False, "IsPrimaryKey": False,
             "AutoIncrement": False, "KeepUnique": False},
            {"name": "Bucket", "type": "INTEGER", "remapKey": "Buckets:ID:Name", "PreventNull": True,
             "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False}]}
        ])

        # Represents an instance of the schema; there is one sqlib.Database instance per sqlite db file
        self.database = sqlib.Database(self.databaseSchema, "SPENT-SQLIB.db")

    def testExecute(self):
        print("Execute Test;")
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

        print(result)

        connection1.disconnect()
        connection2.disconnect()

        result = connection2.execute("SELECT * FROM TransactionGroups")  # This is dangerous
        result = connection1.execute("SELECT * FROM Buckets")  # This is dangerous

    def testAPI(self):
        print("API Test;")
        connection3 = self.database.getConnection("API-Test")

        connection3.connect()

        #TODO: Query Filters
        filter = None # Unimplemented
        someID = 54
        someIDs = [4, 6, 56, 23, 29]

        # Get By ID
        row = connection3.getRow(TABLE_Transactions, someID)
        amount = row.getValue(COLUMN_Amount)

        newAmount = 100000000
        row.setValue(COLUMN_Amount, newAmount)
        connection3.deleteRow(TABLE_Transactions, someID)

        newRow = {COLUMN_Amount: 300.45, COLUMN_Memo: "A test transaction"}
        returnValue = connection3.createRow(TABLE_Transactions, newRow)
        # returnValue will either be the ID of the new row or the new row itself


        # Get Selection
        rowSelection = connection3.select(TABLE_Transactions, filter)

        #OR

        # Get BY ID's; This returns a RowSelection
        rows = connection3.getRows(TABLE_Transactions, someIDs)

        amounts = rows.getValues(COLUMN_Amount)
        rows.setValues(COLUMN_Amount, newAmount)
        rows.deleteRows()


spentdb = SPENTDB()
spentdb.testExecute()
spentdb.testAPI()