import sqlite3 as sql

class Row:
    def __init__(self, cache):
        self.cache = cache

    def getColumnCount(self) -> int:
        pass

    def getColumnByIndex(self) -> 'Column':
        pass

    def getColumnByName(self):
        pass

class TableRow(Row):
    def __init__(self, rowID, table):
        self.table = table
        self.rowID = rowID

    def getRowID(self):
        return self.rowID

    def getColumnByName(self):
        pass

class Column:
    def getIndex(self):
        pass

    def getName(self):
        pass

    def getValue(self, row):
        pass

class TableColumn(Column):
    def __init__(self, table):
        self.table = table

class VirtualColumn(Column):
    pass

class Table:
    def __init__(self, name, tableSchema, virtualColumns):
        self.name = name
        self.columns = None

    def getRowByID(self):
        pass

    def getColumns(self):
        pass

    def getName(self):
        pass

class Database:
    pass

class DatabaseConnection:
    def __init__(self, database, dbPath=":memory:"):
        self.dbPath = dbPath
        self.connection = None
        self.database = database

    def _dbIsConnected_(self, testType, errorMessage):
        if((self.connection is not None) == testType):
            return True
        else:
            print("Error: %s" % errorMessage)
            return False

    def _writeSchema_(self):
        return True

    def connect(self):
        if (self._dbIsConnected_(True, "Database is already connected")):
            self.connection = sql.connect(self.dbPath)
            if(self._writeSchema_()):
                self.connection.row_factory = sql.Row
            else:
                print("Error: Database File schema is incompatible with provided schema")

    def disconnect(self, commit=True):
        if (self._dbIsConnected_(False, "Database is not connected")):
            if(commit):
                self.connection.commit()
            self.connection.close()
            self.connection = None

    def commit(self):
        if (self._dbIsConnected_(False, "Database is not connected")):
            self.commit()

    def execute(self, query):
        if (self._dbIsConnected_(False, "Database is not connected")):
            return self.connection.execute(query)
        return None

class RowDataCache:
    pass

class TableRowDataCache(RowDataCache):
    pass

#---------------------------------

class SPENTDB:
    def __init__(self):
        self.TABLE_Tags = Table("Tags", [
            {"name": "ID", "type": "INTEGER", "PreventNull": True, "IsPrimaryKey": True,
                               "AutoIncrement": True, "KeepUnique": True},
                              {"name": "Name", "type": "TEXT", "PreventNull": True, "IsPrimaryKey": False,
                               "AutoIncrement": False, "KeepUnique": True}])
        self.TABLE_Buckets = Table("Buckets", [
                                 {"name": "ID", "type": "INTEGER", "PreventNull": True, "IsPrimaryKey": True, "AutoIncrement": True, "KeepUnique": True},
                              {"name": "Name", "type": "TEXT", "PreventNull": True, "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": True},
                              {"name": "Parent", "type": "INTEGER", "remapKey": "Buckets:ID:Name", "PreventNull": True, "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False},
                              {"name": "Ancestor", "type": "INTEGER", "remapKey": "Buckets:ID:Name", "PreventNull": True, "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False}])
        self.TABLE_Transactions = Table("Transactions", [
            {"name": "ID", "type": "INTEGER", "PreventNull": True, "IsPrimaryKey": True, "AutoIncrement": True, "KeepUnique": True},
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
                                          "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False}])
        self.TABLE_TransactionTags = Table("TransactionTags", [
            {"name": "TransactionID", "type": "INTEGER", "PreventNull": True, "IsPrimaryKey": False,
                               "AutoIncrement": False, "KeepUnique": False},
                              {"name": "TagID", "type": "INTEGER", "PreventNull": True, "IsPrimaryKey": False,
                               "AutoIncrement": False, "KeepUnique": False},
                              {"isConstraint": True, "constraintValue": "unq UNIQUE (TransactionID, TagID)"}])
        self.TABLE_TransactionGroups = Table("TransactionGroups", [
            {"name": "ID", "type": "INTEGER", "PreventNull": True, "IsPrimaryKey": True,
                               "AutoIncrement": True, "KeepUnique": True},
                              {"name": "Memo", "type": "TEXT", "PreventNull": False, "IsPrimaryKey": False,
                               "AutoIncrement": False, "KeepUnique": False},
                              {"name": "Bucket", "type": "INTEGER", "remapKey": "Buckets:ID:Name", "PreventNull": True,
                               "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False}])

        self.database = Database([self.TABLE_Buckets, self.TABLE_Tags, self.TABLE_TransactionGroups, self.TABLE_Transactions, self.TABLE_TransactionTags])

        self.connection1 = DatabaseConnection(self.database)
        self.connect()

        self.disconnect()