from SPENT import SQLIB as sqlib

class EnumTagsTable(sqlib.EnumTable):
    ID = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=True, autoIncrement=True, keepUnique=True)
    Name = sqlib.TableColumn(sqlib.EnumColumnType.TEXT, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=True)

    def getTableName(self):
        return "Tags"

    def getIDColumn(self):
        return EnumTagsTable.ID

def getBalance():
    return 100

class EnumBucketsTable(sqlib.EnumTable):
    ID = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=True, autoIncrement=True, keepUnique=True)
    Name = sqlib.TableColumn(sqlib.EnumColumnType.TEXT, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=True)
    Parent = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False, properties={"remapKey": "Buckets:ID:Name"})
    Ancestor = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False, properties={"remapKey": "Buckets:ID:Name"})
    Balance = sqlib.VirtualColumn(sqlib.EnumColumnType.INTEGER, getBalance)

    def getTableName(self):
        return "Buckets"

    def getIDColumn(self):
        return EnumBucketsTable.ID

class EnumTransactionTable(sqlib.EnumTable):
    ID = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=True, autoIncrement=True, keepUnique=True)
    Status = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False, properties={"remapKey": "StatusMap:ID:Name"})
    TransDate = sqlib.TableColumn(sqlib.EnumColumnType.DATE, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    PostDate = sqlib.TableColumn(sqlib.EnumColumnType.DATE, preventNull=False, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    Amount = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    SourceBucket = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False, properties={"remapKey": "Buckets:ID:Name"})
    DestBucket = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False, properties={"remapKey": "Buckets:ID:Name"})
    Memo = sqlib.TableColumn(sqlib.EnumColumnType.TEXT, preventNull=False, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    Payee = sqlib.TableColumn(sqlib.EnumColumnType.TEXT, preventNull=False, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    GroupID = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False)

    def getTableName(self):
        return "Transactions"

    def getIDColumn(self):
        return EnumTransactionTable.ID

class EnumTransactionTagsTable(sqlib.EnumTable):
    TransactionID = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    TagID = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    #{"isConstraint": True, "constraintValue": "unq UNIQUE (TransactionID, TagID)"}

    def getTableName(self):
        return "TransactionTags"

    def getIDColumn(self):
        return EnumTransactionTagsTable.ID

class EnumTransactionGroupsTable(sqlib.EnumTable):
    ID = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=True, autoIncrement=True, keepUnique=True)
    Memo = sqlib.TableColumn(sqlib.EnumColumnType.TEXT, preventNull=False, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    Bucket = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False, properties={"remapKey": "Buckets:ID:Name"})

    def getTableName(self):
        return "TransactionGroups"

    def getIDColumn(self):
        return EnumTransactionGroupsTable.ID

class SPENTDB:
    def __init__(self):
        # Represents an instance of the schema; there is one sqlib.Database instance per sqlite db file
        self.database = sqlib.Database("SPENT-SQLIB.db")

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
        row = EnumTransactionTable.getRow(connection3, someID)
        print("Returned Row: %s" % row)
        #amount = row[TransactionsTable.Amount] #TODO: Implement this shorthand
        amount = row.getValue(EnumTransactionTable.Amount)
        print("Row Amount: %s" % amount)



        newAmount = 100000000
        #row[TransactionsTable.Amount] = newAmount #TODO: Implement this shorthand
        row.setValue(EnumTransactionTable.Amount, newAmount)
        EnumTransactionTable.deleteRow(connection3, someID)

        newRow = {EnumTransactionTable.Amount: 300.45, EnumTransactionTable.Memo: "A test transaction"}
        returnValue = EnumTransactionTable.createRow(connection3, newRow)
        # returnValue will either be the ID of the new row or the new row itself


        # Get Selection
        rowSelection = EnumTransactionTable.select(connection3, filter)

        #OR

        # Get BY ID's; This returns a RowSelection
        rows = EnumTransactionTable.getRows(connection3, someIDs)

        #amounts = rows[TransactionsTable.Amount] #TODO: Implement this shorthand
        amounts = rows.getValues(EnumTransactionTable.Amount)
        #rows[TransactionsTable.Amount] = newAmount #TODO: Implement this shorthand
        rows.setValues(EnumTransactionTable.Amount, newAmount)

        rows.deleteRows()

spentdb = SPENTDB()
spentdb.testExecute()
spentdb.testAPI()