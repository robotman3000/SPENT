from typing import Optional

from SPENT import SQLIB as sqlib
from SPENT import LOGGER as log

log.initLogger()
logman = log.getLogger("Main")

class EnumTagsTable(sqlib.EnumTable):
    id = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=True, autoIncrement=True, keepUnique=True)
    Name = sqlib.TableColumn(sqlib.EnumColumnType.TEXT, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=True)

    def getTableName(self):
        return "Tags"

    def getIDColumn(self):
        return EnumTagsTable.id

    def getRowClass(self, rowData):
        return Tag

def generateAncestorValue(row, column, value):
    print("Auto Gen!!!!!!!")

def getBucketType(source, tableName, columnName):
    if source.getValue(EnumBucketsTable.Ancestor) == -1:
        return BucketTypeEnum.ACCOUNT.value;
    return BucketTypeEnum.BUCKET.value;

class EnumBucketsTable(sqlib.EnumTable):
    id = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=True, autoIncrement=True, keepUnique=True)
    Name = sqlib.TableColumn(sqlib.EnumColumnType.TEXT, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=True)
    Parent = sqlib.LinkedColumn(sqlib.EnumColumnType.INTEGER, preventNull=False, isPrimaryKey=False, autoIncrement=False, keepUnique=False, properties={"remapKey": "Buckets:id:Name"}, localKey='id')
    Ancestor = sqlib.LinkedColumn(sqlib.EnumColumnType.INTEGER, preventNull=False, isPrimaryKey=False, autoIncrement=False, keepUnique=False, properties={"remapKey": "Buckets:id:Name", sqlib.PROPERTY_AUTOGENERATE: generateAncestorValue}, localKey='id')
    Type = sqlib.VirtualColumn(sqlib.EnumColumnType.INTEGER, getBucketType)

    def onInit(self, connection):
        if connection.canExecuteUnsafe():
            #connection.execute("PRAGMA foreign_keys = OFF")
            #print(connection.execute("PRAGMA foreign_keys")[0][0])
            try:
                if self.getRow(connection, -1) is None:
                    self.createRow(connection, {EnumBucketsTable.id: -1, EnumBucketsTable.Name: "Root", EnumBucketsTable.Parent: None, EnumBucketsTable.Ancestor: None})
            except Exception as e:
                logman.exception(e)
            #connection.execute("PRAGMA foreign_keys = ON;")
        else:
            logman.warning("Failed to completely init Buckets table")

    def getTableName(self):
        return "Buckets"

    def getIDColumn(self):
        return EnumBucketsTable.id

    def getRowClass(self, rowData):
        #print(rowData)
        val = rowData.getValue(EnumBucketsTable.Ancestor)
        if val is None or val < 0:
            return Account
        return Bucket

def checkIsTransfer(source, tableName, columnName):
    return (source.getSourceBucketID() != -1) and (source.getDestBucketID() != -1)

def getTransactionType(source, tableName, columnName):
    # 00 = Transfer;
    # 01 = Deposit;
    # 10 = Withdrawal:
    # 11 = Invalid

    sourceBucket = (source.getValue(EnumTransactionTable.SourceBucket) != -1);
    dest = (source.getValue(EnumTransactionTable.DestBucket) != -1);
    if sourceBucket and dest:
        # Transfer
        return TransactionTypeEnum.Transfer.value
    elif not sourceBucket and dest:
        # Deposit
        return TransactionTypeEnum.Deposit.value
    elif sourceBucket and not dest:
        # Withdrawal
        return TransactionTypeEnum.Withdrawal.value
    return 3

class EnumTransactionTable(sqlib.EnumTable):
    id = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=True, autoIncrement=True, keepUnique=True)
    Status = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False, properties={"remapKey": "StatusMap:id:Name"})
    TransDate = sqlib.TableColumn(sqlib.EnumColumnType.DATE, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    PostDate = sqlib.TableColumn(sqlib.EnumColumnType.DATE, preventNull=False, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    Amount = sqlib.TableColumn(sqlib.EnumColumnType.DECIMAL, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    SourceBucket = sqlib.LinkedColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False, properties={"remapKey": "Buckets:id:Name"}, foreignKey=EnumBucketsTable.id)
    DestBucket = sqlib.LinkedColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False, properties={"remapKey": "Buckets:id:Name"}, foreignKey=EnumBucketsTable.id)
    Memo = sqlib.TableColumn(sqlib.EnumColumnType.TEXT, preventNull=False, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    Payee = sqlib.TableColumn(sqlib.EnumColumnType.TEXT, preventNull=False, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    IsTransfer = sqlib.VirtualColumn(sqlib.EnumColumnType.INTEGER, checkIsTransfer)
    Type = sqlib.VirtualColumn(sqlib.EnumColumnType.INTEGER, getTransactionType)

    def getTableName(self):
        return "Transactions"

    def getIDColumn(self):
        return EnumTransactionTable.id

    def getRowClass(self, rowData):
        return Transaction

class EnumTransactionTagsTable(sqlib.EnumTable):
    id = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=True, autoIncrement=True, keepUnique=True)
    TransactionID = sqlib.LinkedColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False, foreignKey=EnumTransactionTable.id)
    TagID = sqlib.LinkedColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False, foreignKey=EnumTagsTable.id)

    def getTableName(self):
        return "TransactionTags"

    def getIDColumn(self):
        #TODO: This function doesn't account for the possibility of a composite key/id
        #return sqlib.CompositeKey(EnumTransactionTagsTable.TransactionID, EnumTransactionTagsTable.TagID)
        #return [EnumTransactionTagsTable.TagID]
        return EnumTransactionTagsTable.id

    def getConstraints(self):
        return [
            "unq UNIQUE (%s, %s)" % (EnumTransactionTagsTable.TransactionID.name, EnumTransactionTagsTable.TagID.name),
            #"tagCompositeKey PRIMARY KEY(%s, %s)" % (EnumTransactionTagsTable.TransactionID.name, EnumTransactionTagsTable.TagID.name),
        ]

class Tag(sqlib.TableRow):
    def getID(self) -> int:
        return self.getValue(EnumTagsTable.id)

    def getName(self) -> str:
        return self.getValue(EnumTagsTable.Name)

class Bucket(sqlib.TableRow):
    def getID(self) -> int:
        return self.getValue(EnumBucketsTable.id)

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
        return self.getValue(EnumTransactionTable.id)

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

class BucketTypeEnum(sqlib.EnumBase):
    BUCKET = 0
    ACCOUNT = 1

class SPENT_DB_V1_1(sqlib.DatabaseSchema):
    @classmethod
    def getName(self):
        return "SPENTDB"

    @classmethod
    def getVersion(self):
        return 1.1

    @classmethod
    def getTables(self):
        return [EnumBucketsTable, EnumTransactionTable, EnumTagsTable, EnumTransactionTagsTable]