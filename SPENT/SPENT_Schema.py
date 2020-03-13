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

#def getAvailBucketTreeBalance(source, tableName, columnName):
#    return spent.util.getAvailableBalance(source, True)

#def getPostedBucketTreeBalance(source, tableName, columnName):
#    return spent.util.getPostedBalance(source, True)

#def getAvailBucketBalance(source, tableName, columnName):
#    return spent.util.getAvailableBalance(source)

#def getPostedBucketBalance(source, tableName, columnName):
#    return spent.util.getPostedBalance(source)

# TODO: Should these vir columns be kept around?
#def getBucketTransactions(source, tableName, columnName):
#    return spent.util.getBucketTransactionsID(source)

#def getAllBucketTransactions(source, tableName, columnName):
#    return spent.util.getAllBucketTransactionsID(source)

#def getBucketChildren(source, tableName, columnName):
#    return spent.util.getBucketChildrenID(source)

#def getAllBucketChildren(source, tableName, columnName):
#    return spent.util.getAllBucketChildrenID(source)

class EnumBucketsTable(sqlib.EnumTable):
    ID = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=True, autoIncrement=True, keepUnique=True)
    Name = sqlib.TableColumn(sqlib.EnumColumnType.TEXT, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=True)
    Parent = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False, properties={"remapKey": "Buckets:ID:Name"})
    Ancestor = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False, properties={"remapKey": "Buckets:ID:Name"})
    #Balance = sqlib.VirtualColumn(sqlib.EnumColumnType.INTEGER, getAvailBucketBalance)
    #PostedBalance = sqlib.VirtualColumn(sqlib.EnumColumnType.INTEGER, getPostedBucketBalance)
    #TreeBalance = sqlib.VirtualColumn(sqlib.EnumColumnType.INTEGER, getAvailBucketTreeBalance)
    #PostedTreeBalance = sqlib.VirtualColumn(sqlib.EnumColumnType.INTEGER, getPostedBucketTreeBalance)

    # TODO: Deprecated
    #Transactions = sqlib.VirtualColumn(sqlib.EnumColumnType.INTEGER, getBucketTransactions)
    #AllTransactions = sqlib.VirtualColumn(sqlib.EnumColumnType.INTEGER, getAllBucketTransactions)
    #Children = sqlib.VirtualColumn(sqlib.EnumColumnType.INTEGER, getBucketChildren)
    #AllChildren = sqlib.VirtualColumn(sqlib.EnumColumnType.INTEGER, getAllBucketChildren)

    def getTableName(self):
        return "Buckets"

    def getIDColumn(self):
        return EnumBucketsTable.ID

    def getRowClass(self, rowData):
        #print(rowData)
        if rowData.getValue(EnumBucketsTable.Ancestor) < 0:
            return Account
        return Bucket

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
    Amount = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    SourceBucket = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False, properties={"remapKey": "Buckets:ID:Name"})
    DestBucket = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False, properties={"remapKey": "Buckets:ID:Name"})
    Memo = sqlib.TableColumn(sqlib.EnumColumnType.TEXT, preventNull=False, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    Payee = sqlib.TableColumn(sqlib.EnumColumnType.TEXT, preventNull=False, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    GroupID = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    IsTransfer = sqlib.VirtualColumn(sqlib.EnumColumnType.INTEGER, checkIsTransfer)
    Type = sqlib.VirtualColumn(sqlib.EnumColumnType.INTEGER, getTransactionType)

    def getTableName(self):
        return "Transactions"

    def getIDColumn(self):
        return EnumTransactionTable.ID

    def getRowClass(self, rowData):
        return Transaction

class EnumTransactionTagsTable(sqlib.EnumTable):
    TransactionID = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    TagID = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False)

    def getTableName(self):
        return "TransactionTags"

    def getIDColumn(self):
        return EnumTransactionTagsTable.ID

    def getConstraints(self):
        return [
            "unq UNIQUE (%s, %s)" % (EnumTransactionTagsTable.TransactionID.name, EnumTransactionTagsTable.TagID.name)
        ]

class EnumTransactionGroupsTable(sqlib.EnumTable):
    ID = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=True, autoIncrement=True, keepUnique=True)
    Memo = sqlib.TableColumn(sqlib.EnumColumnType.TEXT, preventNull=False, isPrimaryKey=False, autoIncrement=False, keepUnique=False)
    Bucket = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=False, properties={"remapKey": "Buckets:ID:Name"})

    def getTableName(self):
        return "TransactionGroups"

    def getIDColumn(self):
        return EnumTransactionGroupsTable.ID

    def getRowClass(self, rowData):
        return TransactionGroup

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

#++++++++++++++++++++++++++++

# def getTagName(source, tableName, columnName):
#	return self.selectTableRowsColumns("Tags", [source.getValue("TagID")], ["Name"])[0]

# self.registerVirtualColumn("TransactionTags", "TagName", getTagName)

# self.registerTableSchema("StatusMap", None, ["Void", "Uninitiated", "Submitted", "Post-Pending", "Complete", "Reconciled"])

# def getGroupAmount(source, tableName, columnName):
#	print("Amount12345")
#	ids = self.util.getAllBucketChildrenID(source.getBucket())
#	ids.append(source.getBucket().getID())  # We can't forget ourself
#	idStr = ", ".join(map(str, ids))
#
#			query = "SELECT IFNULL(SUM(Amount), 0) FROM (SELECT -1*SUM(Amount) AS \"Amount\" FROM Transactions WHERE SourceBucket IN (%s) AND GroupID == %s UNION ALL SELECT SUM(Amount) AS \"Amount\" FROM Transactions WHERE DestBucket IN (%s) AND GroupID == %s)" % (
#				idStr, source.getID(), idStr, source.getID())
#
#			result = self._rawSQL_(query)
#			return round(float(result[0][0]), 2)

#		self.registerVirtualColumn("TransactionGroups", "Amount", getGroupAmount)

