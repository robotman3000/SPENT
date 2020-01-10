from SPENT import SQLIB as sqlib

class SPENTDB:
    def __init__(self):
        self.TABLE_Tags = sqlib.Table("Tags", [
            {"name": "ID", "type": "INTEGER", "PreventNull": True, "IsPrimaryKey": True,
                               "AutoIncrement": True, "KeepUnique": True},
                              {"name": "Name", "type": "TEXT", "PreventNull": True, "IsPrimaryKey": False,
                               "AutoIncrement": False, "KeepUnique": True}])
        self.TABLE_Buckets = sqlib.Table("Buckets", [
                                 {"name": "ID", "type": "INTEGER", "PreventNull": True, "IsPrimaryKey": True, "AutoIncrement": True, "KeepUnique": True},
                              {"name": "Name", "type": "TEXT", "PreventNull": True, "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": True},
                              {"name": "Parent", "type": "INTEGER", "remapKey": "Buckets:ID:Name", "PreventNull": True, "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False},
                              {"name": "Ancestor", "type": "INTEGER", "remapKey": "Buckets:ID:Name", "PreventNull": True, "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False}])
        self.TABLE_Transactions = sqlib.Table("Transactions", [
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
        self.TABLE_TransactionTags = sqlib.Table("TransactionTags", [
            {"name": "TransactionID", "type": "INTEGER", "PreventNull": True, "IsPrimaryKey": False,
                               "AutoIncrement": False, "KeepUnique": False},
                              {"name": "TagID", "type": "INTEGER", "PreventNull": True, "IsPrimaryKey": False,
                               "AutoIncrement": False, "KeepUnique": False},
                              {"isConstraint": True, "constraintValue": "unq UNIQUE (TransactionID, TagID)"}])
        self.TABLE_TransactionGroups = sqlib.Table("TransactionGroups", [
            {"name": "ID", "type": "INTEGER", "PreventNull": True, "IsPrimaryKey": True,
                               "AutoIncrement": True, "KeepUnique": True},
                              {"name": "Memo", "type": "TEXT", "PreventNull": False, "IsPrimaryKey": False,
                               "AutoIncrement": False, "KeepUnique": False},
                              {"name": "Bucket", "type": "INTEGER", "remapKey": "Buckets:ID:Name", "PreventNull": True,
                               "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False}])

        self.databaseSchema = sqlib.DatabaseSchema(1, [self.TABLE_Buckets, self.TABLE_Tags, self.TABLE_TransactionGroups, self.TABLE_Transactions, self.TABLE_TransactionTags])

        # Represents an instance of the schema; there is one sqlib.Database instance per sqlite db file
        self.database = sqlib.Database(self.databaseSchema, "SPENT-SQLIB.db")

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

spentdb = SPENTDB()