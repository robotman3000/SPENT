from typing import Optional

from SPENT import SQLIB as sqlib
from SPENT import LOGGER as log

log.initLogger()
logman = log.getLogger("Main")

class EnumRowIDTable(sqlib.EnumTable):
    TableName = sqlib.TableColumn(sqlib.EnumColumnType.TEXT, preventNull=True, isPrimaryKey=True, autoIncrement=False, keepUnique=True)
    RowIndex = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False)

    def getTableName(self):
        return "rowID"

    def getIDColumn(self):
        return EnumRowIDTable.TableName

    def getRowClass(self, rowData):
        return

class TableIndexRow(sqlib.TableRow):
    def getTableName(self):
        return self.getValue(EnumRowIDTable.TableName)

    def getRowIndexValue(self):
        return self.getValue(EnumRowIDTable.RowIndex)

    def incrementRowIndex(self, tableKey):
        oldValue = self.getRowIndexValue()
        newValue = oldValue + 1
        self.setValue(EnumRowIDTable.RowIndex, newValue)
        return newValue

class EnumTagsTable(sqlib.EnumTable):
    ID = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=True, autoIncrement=True, keepUnique=True)
    Name = sqlib.TableColumn(sqlib.EnumColumnType.TEXT, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=True)

    def getTableName(self):
        return "Tags"

    def getIDColumn(self):
        return EnumTagsTable.ID

    def getRowClass(self, rowData):
        return Tag

class EnumBucketsTable(sqlib.EnumTable):
    ID = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=True, autoIncrement=True, keepUnique=True)
    Name = sqlib.TableColumn(sqlib.EnumColumnType.TEXT, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=True)
    Parent = sqlib.LinkedColumn(sqlib.EnumColumnType.INTEGER, preventNull=False, isPrimaryKey=False, autoIncrement=False, keepUnique=False, properties={"remapKey": "Buckets:ID:Name"}, localKey='ID')
    Ancestor = sqlib.LinkedColumn(sqlib.EnumColumnType.INTEGER, preventNull=False, isPrimaryKey=False, autoIncrement=False, keepUnique=False, properties={"remapKey": "Buckets:ID:Name"}, localKey='ID')

    def onInit(self, connection):
        if connection.canExecuteUnsafe():
            #connection.execute("PRAGMA foreign_keys = OFF")
            print(connection.execute("PRAGMA foreign_keys")[0][0])
            try:
                self.createRow(connection, {EnumBucketsTable.ID: -1, EnumBucketsTable.Name: "Root", EnumBucketsTable.Parent: None, EnumBucketsTable.Ancestor: None})
            except Exception as e:
                logman.exception(e)
            #connection.execute("PRAGMA foreign_keys = ON;")
        else:
            logman.warning("Failed to completely init Buckets table")

    def getTableName(self):
        return "Buckets"

    def getIDColumn(self):
        return EnumBucketsTable.ID

    def getRowClass(self, rowData):
        #print(rowData)
        val = rowData.getValue(EnumBucketsTable.Ancestor)
        if val is None or val < 0:
            return Account
        return Bucket

class EnumTransactionGroupsTable(sqlib.EnumTable):
    ID = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=True, autoIncrement=True, keepUnique=True)
    Memo = sqlib.TableColumn(sqlib.EnumColumnType.TEXT, preventNull=False, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    Bucket = sqlib.LinkedColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False, properties={"remapKey": "Buckets:ID:Name"}, foreignKey=EnumBucketsTable.ID)

    def getTableName(self):
        return "TransactionGroups"

    def getIDColumn(self):
        return EnumTransactionGroupsTable.ID

    def getRowClass(self, rowData):
        return TransactionGroup

    def onInit(self, connection):
        if connection.canExecuteUnsafe():
            #connection.execute("PRAGMA foreign_keys = OFF")
            print(connection.execute("PRAGMA foreign_keys")[0][0])
            try:
                self.createRow(connection, {EnumTransactionGroupsTable.ID: -1, EnumTransactionGroupsTable.Memo: "Default Group", EnumTransactionGroupsTable.Bucket: -1})
            except Exception as e:
                logman.exception(e)
            #connection.execute("PRAGMA foreign_keys = ON;")
        else:
            logman.warning("Failed to completely init Buckets table")

def checkIsTransfer(source, tableName, columnName):
    return (source.getSourceBucketID() is not -1) and (source.getDestBucketID() is not -1)

def getTransactionType(source, tableName, columnName):
    # 00 = Transfer;
    # 01 = Deposit;
    # 10 = Withdrawal:
    # 11 = Invalid

    sourceBucket = (source.getValue(EnumTransactionTable.SourceBucket) != -1);
    dest = (source.getValue(EnumTransactionTable.DestBucket) != -1);
    if sourceBucket and dest:
        # Transfer
        return 0
    elif not sourceBucket and dest:
        # Deposit
        return 1
    elif sourceBucket and not dest:
        # Withdrawal
        return 2
    return 3

class EnumTransactionTable(sqlib.EnumTable):
    ID = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=True, autoIncrement=True, keepUnique=True)
    Status = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False, properties={"remapKey": "StatusMap:ID:Name"})
    TransDate = sqlib.TableColumn(sqlib.EnumColumnType.DATE, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    PostDate = sqlib.TableColumn(sqlib.EnumColumnType.DATE, preventNull=False, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    Amount = sqlib.TableColumn(sqlib.EnumColumnType.DECIMAL, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    SourceBucket = sqlib.LinkedColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False, properties={"remapKey": "Buckets:ID:Name"}, foreignKey=EnumBucketsTable.ID)
    DestBucket = sqlib.LinkedColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False, properties={"remapKey": "Buckets:ID:Name"}, foreignKey=EnumBucketsTable.ID)
    Memo = sqlib.TableColumn(sqlib.EnumColumnType.TEXT, preventNull=False, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    Payee = sqlib.TableColumn(sqlib.EnumColumnType.TEXT, preventNull=False, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    GroupID = sqlib.LinkedColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False, foreignKey=EnumTransactionGroupsTable.ID)
    IsTransfer = sqlib.VirtualColumn(sqlib.EnumColumnType.INTEGER, checkIsTransfer)
    Type = sqlib.VirtualColumn(sqlib.EnumColumnType.INTEGER, getTransactionType)

    def getTableName(self):
        return "Transactions"

    def getIDColumn(self):
        return EnumTransactionTable.ID

    def getRowClass(self, rowData):
        return Transaction

class EnumTransactionTagsTable(sqlib.EnumTable):
    TransactionID = sqlib.LinkedColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False, foreignKey=EnumTransactionTable.ID)
    TagID = sqlib.LinkedColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False, foreignKey=EnumTagsTable.ID)

    def getTableName(self):
        return "TransactionTags"

    def getIDColumn(self):
        return EnumTransactionTagsTable.ID

    def getConstraints(self):
        return [
            "unq UNIQUE (%s, %s)" % (EnumTransactionTagsTable.TransactionID.name, EnumTransactionTagsTable.TagID.name)
        ]

class Tag(sqlib.TableRow):
    def getID(self) -> int:
        return self.getValue(EnumTagsTable.ID)

    def getName(self) -> str:
        return self.getValue(EnumTagsTable.Name)

class Bucket(sqlib.TableRow):
    def getID(self) -> int:
        return self.getValue(EnumBucketsTable.ID)

    def getName(self) -> str:
        return self.getValue(EnumBucketsTable.Name)

    def getParentID(self) -> Optional['Bucket']:
        return self.getValue(EnumBucketsTable.Parent)

    def getAncestorID(self) -> Optional['Bucket']:
        return self.getValue(EnumBucketsTable.Ancestor)

class Account(Bucket):
    def getParent(self) -> Optional[Bucket]:
        return None

    def getParentAccount(self) -> 'Account':
        return self

    def getAncestor(self) -> Optional[Bucket]:
        return None

class Transaction(sqlib.TableRow):
    def getID(self) -> int:
        return self.getValue(EnumTransactionTable.ID)

    def getStatus(self) -> int:
        return self.getValue(EnumTransactionTable.Status)

    def getTransactionDate(self) -> str:
        return self.getValue(EnumTransactionTable.TransDate)

    def getPostDate(self) -> str:
        return self.getValue(EnumTransactionTable.PostDate)

    def getAmount(self) -> str:
        return self.getValue(EnumTransactionTable.Amount)

    def getMemo(self) -> str:
        return self.getValue(EnumTransactionTable.Memo)

    def getPayee(self) -> str:
        return self.getValue(EnumTransactionTable.Payee)

    def getSourceBucketID(self) -> Optional[Bucket]:
        return self.getValue(EnumTransactionTable.SourceBucket)

    def getDestBucketID(self) -> Optional[Bucket]:
        return self.getValue(EnumTransactionTable.DestBucket)

    def isTransfer(self) -> bool:
        return self.getValue(EnumTransactionTable.IsTransfer)

    def getType(self) -> int:
        return self.getValue(EnumTransactionTable.Type)

class TransactionGroup(sqlib.TableRow):
    def getID(self) -> int:
        return self.getValue(EnumTransactionGroupsTable.ID)

    def getMemo(self) -> str:
        return self.getValue(EnumTransactionGroupsTable.Memo)

    def getBucketID(self) -> Optional[Bucket]:
        return self.getValue(EnumTransactionGroupsTable.Bucket)

class TransactionStatusEnum(sqlib.EnumBase):
    Void = 0
    Uninitiated = 1
    Submitted = 2
    PostPending = 3
    Complete = 4
    Reconciled = 5

class TransactionTypeEnum(sqlib.EnumBase):
    Transfer = 0
    Deposit = 1
    Withdrawal = 2