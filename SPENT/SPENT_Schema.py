from typing import Optional

from SPENT import SQLIB as sqlib
from SPENT import LOGGER as log

log.initLogger()
logman = log.getLogger("Main")

class EnumTagsTable(sqlib.EnumTable):
    ID = sqlib.TableColumn(sqlib.EnumColumnType.INTEGER, preventNull=True, isPrimaryKey=True, autoIncrement=True, keepUnique=True)
    Name = sqlib.TableColumn(sqlib.EnumColumnType.TEXT, preventNull=True, isPrimaryKey=False, autoIncrement=False, keepUnique=True)

    def getTableName(self):
        return "Tags"

    def getIDColumn(self):
        return EnumTagsTable.ID

    def getRowClass(self):
        return Tag

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

    def getRowClass(self):
        return Bucket

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

    def getRowClass(self):
        return Transaction

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

    def getRowClass(self):
        return TransactionGroup

class Tag(sqlib.TableRow):
    def getID(self) -> int:
        return self.getValue(EnumTagsTable.ID)

    def getName(self) -> str:
        return self.getValue(EnumTagsTable.Name)

    #def setName(self, name: str) -> None:
	#	self.updateValue("Name", name)

	#def getTransactions(self) -> List['Transaction']:
	#	transIDs = self.database.selectTableRowsColumnsWhere("TransactionTags", ["TransactionID"], SQL_WhereStatementBuilder("TagID == %d" % self.getID()))
	#	if len(transIDs) > 0:
	#		transList = self.database.getTransactionsWhere(SQL_WhereStatementBuilder("ID in (%s)" % ", ".join([asStr(row.getValue("TransactionID")) for row in transIDs])))
	#		return transList
	#	return []

	#def applyToTransactions(self, transactions: List['Transaction']) -> None:
	#	myID = self.getID() # No need to query the table N > 1 times for the same thing, once will do
	#	for t in transactions:
	#		self.database._tableInsertInto_("TransactionTags", {"TransactionID": t.getID(), "TagID": myID})

	#def removeFromTransactions(self, transactions: List['Transaction']) -> None:
	#	idList = [asStr(t.getID()) for t in transactions if t is not None]
	#	if len(idList) > 0:
	#		where = SQL_WhereStatementBuilder("TagID == %s" % self.getID()).AND("TransactionID in (%s)" % ", ".join(idList))
	#		self.database.deleteTableRowsWhere("TransactionTags", where)

class Bucket(sqlib.TableRow):
    def getID(self) -> int:
        return self.getValue(EnumBucketsTable.ID)

    def getName(self) -> str:
        return self.getValue(EnumBucketsTable.Name)

    #def getParent(self) -> Optional['Bucket']:
    #    parentID = self.getValue(EnumBucketsTable.Parent)
    #    return cast(SpentDBManager, self.database).getBucket(parentID)

    #def getAncestor(self) -> Optional['Bucket']:
    #    ancestorID = self.getValue(EnumBucketsTable.Ancestor)
    #    return cast(SpentDBManager, self.database).getBucket(ancestorID)

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

    #def getSourceBucket(self) -> Optional[Bucket]:
    #    return cast(SpentDBManager, self.database).getBucket(asInt(self.getValue("SourceBucket")))

    #def getDestBucket(self) -> Optional[Bucket]:
    #    return cast(SpentDBManager, self.database).getBucket(asInt(self.getValue("DestBucket")))

    def isTransfer(self) -> bool:
        return self.getValue(EnumTransactionTable.IsTransfer)

    def getType(self) -> int:
        return self.getValue(EnumTransactionTable.Type)

class TransactionGroup(sqlib.TableRow):
    def getID(self) -> int:
        return self.getValue(EnumTransactionGroupsTable.ID)

    def getMemo(self) -> str:
        return self.getValue(EnumTransactionGroupsTable.Memo)

    #def getBucket(self) -> Optional[Bucket]:
    #    return cast(SpentDBManager, self.database).getBucket(asInt(self.getValue("Bucket")))