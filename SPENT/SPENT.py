from datetime import date
from SPENT.sqlite3_DOM import *
from typing import Set, cast

#Verb layer features
#	Reconcile
#	Import/Export
#	Report Generation
#	Account/Bucket Balance Calculation

#Transaction Tagging
#Transaction Grouping?

def getCurrentDateStr() -> str:
	return str(date.today())

def asInt(obj: Any) -> int:
	if type(obj) is int:
		return obj
	elif type(obj) is str:
		return int(obj)
	return int(str(obj))

def asFloat(obj: Any) -> float:
	if type(obj) is float:
		return obj
	elif type(obj) is str:
		return float(obj)
	return float(str(obj))

def asStr(obj: Any) -> str:
	if type(obj) is str:
		return obj
	return str(obj)

class Tag:
	def getName(self):
		pass

	def getTransactions(self):
		pass

class TagManager:
	def __init__(self, database: 'SpentDBManager'):
		self.db = database

	def getTransactionTags(self, transaction: 'Transation') -> List[Tag]:
		pass

	def getTag(self):
		pass

	def createTag(self):
		pass

	def deleteTag(self):
		pass

class SpentUtil():
	def __init__(self, spentDB):
		self._spentDB_ = spentDB

	def registerUtilityColumns(self):
		def getAvailBucketBalance(source, tableName, columnName):
			return self.getAvailableBalance(source)

		def getPostedBucketBalance(source, tableName, columnName):
			return self.getPostedBalance(source)

		self._spentDB_.registerVirtualColumn("Buckets", "Balance", getAvailBucketBalance)
		self._spentDB_.registerVirtualColumn("Buckets", "PostedBalance", getPostedBucketBalance)

		# TODO: SHould these vir columns be kept around?
		def getBucketTransactions(source, tableName, columnName):
			return self.getBucketTransactionsID(source)

		def getAllBucketTransactions(source, tableName, columnName):
			return self.getAllBucketTransactionsID(source)

		def getBucketChildren(source, tableName, columnName):
			return self.getBucketChildrenID(source)

		def getAllBucketChildren(source, tableName, columnName):
			return self.getAllBucketChildrenID(source)

		self._spentDB_.registerVirtualColumn("Buckets", "Transactions", getBucketTransactions)
		self._spentDB_.registerVirtualColumn("Buckets", "AllTransactions", getAllBucketTransactions)
		self._spentDB_.registerVirtualColumn("Buckets", "Children", getBucketChildren)
		self._spentDB_.registerVirtualColumn("Buckets", "AllChildren", getAllBucketChildren)

	def getPostedBalance(self, bucket: 'Bucket') -> float:
		return self._calculateBalance_(bucket, True)

	def getAvailableBalance(self, bucket: 'Bucket') -> float:
		return self._calculateBalance_(bucket)

	def _calculateBalance_(self, bucket: 'Bucket', posted: bool = False) -> float:
		ids = self.getAllBucketChildrenID(bucket)
		ids.append(bucket.getID())  # We can't forget ourself
		idStr = ", ".join(map(str, ids))

		statusStr = ""
		if posted:
			statusStr = "AND Status IN (2, 3)"

		query = "SELECT IFNULL(SUM(Amount), 0) AS \"Amount\" FROM (SELECT -1*SUM(Amount) AS \"Amount\" FROM Transactions WHERE SourceBucket IN (%s) %s UNION ALL SELECT SUM(Amount) AS \"Amount\" FROM Transactions WHERE DestBucket IN (%s) %s)" % (
		idStr, statusStr, idStr, statusStr)
		column = "Amount"

		result = self._spentDB_._rawSQL_(query)
		rows = self._spentDB_.parseRows(result, [column], "Transactions")
		if len(rows) > 0:
			return round(float(rows[0].getValue(column, False)), 2)
		return 0

	def getBucketParentAccount(self, bucket: 'Bucket') -> 'Bucket':
		# Do not reimplement this to use ancestor. This funciton is needed to generate the ancestor ID
		parent = bucket.getParent()
		if parent is None:
			return bucket
		elif parent.getID() == -1:
			return parent

		return self.getBucketParentAccount(parent)

	def getBucketChildren(self, bucket: 'Bucket') -> List['Bucket']:
		return self._spentDB_.getBucketsWhere(SQL_WhereStatementBuilder("%s == %d" % ("Parent", int(bucket.getID()))))

	def getBucketChildrenID(self, bucket: 'Bucket') -> List[int]:
		# TODO: this and the "all" version are inefficent
		return [i.getID() for i in self.getBucketChildren(bucket)]

	def getAllBucketChildren(self, bucket: 'Bucket') -> List['Bucket']:
		children = self.getBucketChildren(bucket)
		newChildren: List[Bucket] = children.copy()
		for i in children:
			newChildren += self.getAllBucketChildren(i)

		# print(newChildren)
		return newChildren

	def getAllBucketChildrenID(self, bucket: 'Bucket') -> List[int]:
		return [i.getID() for i in self.getAllBucketChildren(bucket)]

	def getBucketTransactions(self, bucket: 'Bucket') -> List['Transaction']:
		return self._spentDB_.getTransactionsWhere(
			SQL_WhereStatementBuilder("%s == %s" % ("SourceBucket", bucket.getID())).OR(
				"%s == %s" % ("DestBucket", bucket.getID())))

	def getBucketTransactionsID(self, bucket: 'Bucket') -> List[int]:
		return [i.getID() for i in self.getBucketTransactions(bucket)]

	def getAllBucketTransactions(self, bucket: 'Bucket') -> List['Transaction']:
		allIDList = ", ".join(map(str, self.getAllBucketChildrenID(bucket) + [bucket.getID()]))
		return self._spentDB_.getTransactionsWhere(
			SQL_WhereStatementBuilder("%s IN (%s)" % ("SourceBucket", allIDList)).OR(
				"%s IN (%s)" % ("DestBucket", allIDList)))

	def getAllBucketTransactionsID(self, bucket: 'Bucket') -> List[int]:
		return [i.getID() for i in self.getAllBucketTransactions(bucket)]

class SpentDBManager(DatabaseWrapper):
	def __init__(self, dbFile: str = "SPENT.db"):
		super().__init__(dbFile)
		self.registerTableSchema("Buckets", 
			[{"name": "ID", "type": "INTEGER", "PreventNull": True, "IsPrimaryKey": True, "AutoIncrement": True, "KeepUnique": True},
			 {"name": "Name", "type": "TEXT", "PreventNull": True, "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": True},
			 {"name": "Parent", "type": "INTEGER", "remapKey": "Buckets:ID:Name", "PreventNull": True, "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False},
			 {"name": "Ancestor", "type": "INTEGER", "remapKey": "Buckets:ID:Name", "PreventNull": True, "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False}])

		self.registerTableSchema("Transactions", 
			[{"name": "ID", "type": "INTEGER", "PreventNull": True, "IsPrimaryKey": True, "AutoIncrement": True, "KeepUnique": True},
			 {"name": "Status", "type": "INTEGER", "remapKey": "StatusMap:ID:Name", "PreventNull": True, "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False},
			 {"name": "TransDate", "type": "INTEGER", "PreventNull": True, "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False}, 
			 {"name": "PostDate", "type": "INTEGER", "PreventNull": False, "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False}, 
			 {"name": "Amount", "type": "INTEGER", "PreventNull": True, "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False}, 
			 {"name": "SourceBucket", "type": "INTEGER", "remapKey": "Buckets:ID:Name", "PreventNull": True, "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False},
			 {"name": "DestBucket", "type": "INTEGER", "remapKey": "Buckets:ID:Name", "PreventNull": True, "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False},
			 {"name": "Memo", "type": "TEXT", "PreventNull": False, "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False}, 
			 {"name": "Payee", "type": "TEXT", "PreventNull": False, "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False}])

		self.registerTableSchema("Tags",
			[{"name": "TransactionID", "type": "INTEGER", "PreventNull": True, "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False},
			 {"name": "Name", "type": "TEXT", "PreventNull": True, "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False}])

		self.registerTableSchema("StatusMap", None, ["Uninitiated", "Submitted", "Post-Pending", "Complete"])
		
		def checkIsTransfer(source, tableName, columnName):
			return (source.getSourceBucket() is not None) and (source.getDestBucket() is not None)
		
		def getTransactionType(source, tableName, columnName):
			#00 = Transfer;
			#01 = Deposit;
			#10 = Withdrawal:
			#11 = Invalid
	
			sourceBucket = (source.getValue("SourceBucket") != -1);
			dest = (source.getValue("DestBucket") != -1);
			if sourceBucket and dest:
				#Transfer
				return 0
			elif not sourceBucket and dest:
				#Deposit
				return 1
			elif sourceBucket and not dest:
				#Withdrawal
				return 2
			
			return 3
		
		self.registerVirtualColumn("Transactions", "IsTransfer", checkIsTransfer)
		self.registerVirtualColumn("Transactions", "Type", getTransactionType)
		self.util = SpentUtil(self)

	def createBucket(self, name: str, parent: int) -> Optional['Bucket']:
		#TODO: Verify the data is valid
		ancestor = -1
		if int(parent) != -1:
			par = self.getBucket(int(parent))
			if par is None:
				ancestor = parent
			else:
				ancestor = self.util.getBucketParentAccount(par).getID()

		return self.getBucket(self._tableInsertInto_("Buckets",
                                      {"Name" : str(name),
                                       "Parent" : int(parent),
                                       "Ancestor": ancestor,
                                      })[0][0])
	
	def createTransaction(self, amount: float, status: int = 0, sourceBucket: Optional['Bucket'] = None, destBucket: Optional['Bucket'] = None, transactionDate: Optional[str] = None, postDate: Optional[str] = None, memo: str = "",  payee: str = "") -> 'Transaction':
		#TODO: Verify that all the data is in the correct format
		#print("%s - %s - %s - %s - %s - %s - %s - %s" % (amount, status, sourceBucket, destBucket, transactionDate, postDate, memo, payee))
		return self.getTransaction(self._tableInsertInto_("Transactions", 
									  {"Status" : int(status),
									   "TransDate" : getCurrentDateStr() if transactionDate is None else str(transactionDate),
									   "PostDate" : postDate,
									   "Amount" : float(amount),
									   "SourceBucket" : int(-1 if sourceBucket is None else sourceBucket.getID()),
									   "DestBucket" : int(-1 if destBucket is None else destBucket.getID()),
									   "Memo" : str(memo),
									   "Payee": str(payee)
									  })[0][0])
	
	def createAccount(self, name: str) -> Optional['Bucket']: # TODO: This should return account
		return self.createBucket(name, -1)
	
	def getBucket(self, bucketID: int) -> Optional['Bucket']:
		if bucketID > -1:
			bucket = Bucket(self, bucketID)
			if bucket.getParent() == -1:
				return Account(self, bucketID)
			return bucket
		return None

	def getBucketsWhere(self, where: Optional[SQL_WhereStatementBuilder] = None) -> List['Bucket']:
		nWhere = where
		if nWhere is not None:
			nWhere.insertStatement("AND", "Parent > -1")
		else:
			nWhere = SQL_WhereStatementBuilder("Parent > -1")
		return self._getBucketsWhere_(nWhere)
	
	def getTransaction(self, transactionID: int) -> 'Transaction':
		return Transaction(self, transactionID)
		
	def getTransactionsWhere(self, where: Optional[SQL_WhereStatementBuilder] = None) -> List['Transaction']:
		result = self.selectTableRowsColumnsWhere("Transactions", columnNames=["ID"], where=where)
		transactions = []
		for i in result:
			trans = self.getTransaction(asInt(i.getValue("ID")))
			if trans is not None:
				transactions.append(trans)
			else:
				print("Error: SpentDBManager.getTransactionsWhere: Encountered a None transaction")
		return transactions	
	
	def getAccount(self, accountID: int) -> Optional['Bucket']: #TODO: This should be marked to return account
		return self.getBucket(accountID)
		
	def getAccountsWhere(self, where: Optional[SQL_WhereStatementBuilder] = None) -> List['Bucket']: #TODO: This should be marked to return accounts
		nWhere = where
		if nWhere is not None:
			nWhere.insertStatement("AND", "Parent == -1")
		else:
			nWhere = SQL_WhereStatementBuilder("Parent == -1")
		return self._getBucketsWhere_(nWhere)
	
	def deleteBucket(self, bucket: 'Bucket') -> None:
		where = self.rowsToWhere([asInt(bucket.getID)])
		self.deleteBucketsWhere(where)
		del bucket # Destroy the data our reference points to; to prevent further use
	
	def deleteBucketsWhere(self, where: SQL_WhereStatementBuilder) -> Set[int]:
		return self._deleteBucketsWhere_(where, False)
		
	def deleteTransaction(self, transaction: 'Transaction') -> None:
		where = self.rowsToWhere([asInt(transaction.getID)])
		self.deleteTransactionsWhere(where)
		del transaction # Destroy the data our reference points to; to prevent further use
		
	def deleteTransactionsWhere(self, where: SQL_WhereStatementBuilder):#TODO return List[int]
		if where is None:
			raise ValueError("SpentDBManager.deleteTransactionsWhere: where can't be None")
		self.deleteTableRowsWhere("Transactions", where)
		
	def deleteAccount(self, account: 'Account') -> None:
		where = self.rowsToWhere([asInt(account.getID)])
		self.deleteAccountsWhere(where)
		del account  # Destroy the data our reference points to; to prevent further use
		
	def deleteAccountsWhere(self, where: SQL_WhereStatementBuilder) -> Set[int]:
		return self._deleteBucketsWhere_(where, True)
	
	def _getBucketsWhere_(self, where: SQL_WhereStatementBuilder) -> List['Bucket']:
		result = self.selectTableRowsColumnsWhere("Buckets", ["ID"], where)
		buckets = []
		for i in result:
			bucket = self.getBucket(asInt(i.getValue("ID")))
			if bucket is not None:
				buckets.append(bucket)
			else:
				print("Error: SpentDBManager._getBucketsWhere_: Encountered a None bucket")
		return buckets

	def _deleteBucketsWhere_(self, where: SQL_WhereStatementBuilder, deleteAccounts: bool) -> Set[int]:
		#TODO: This should be rewriten to use less SQL queries

		if where is None:
			raise ValueError("SpentDBManager._deleteBucketsWhere_: where can't be None")
		buckets = self._getBucketsWhere_(where)
		bucketAncestorMap: Dict[int, Set[int]] = {}
		for bucket in buckets:
			ancestor = bucket.getAncestor()
			id = -1
			if ancestor is not None:
				id = ancestor.getID()

			bucketIDs = bucketAncestorMap.get(id, None)
			if bucketIDs is None:
				bucketIDs = set()
				bucketAncestorMap[id] = bucketIDs

			bucketIDs.add(bucket.getID())
			children = self.util.getAllBucketChildrenID(bucket)
			for i in children:
				bucketIDs.add(i)

		print(bucketAncestorMap)

		if deleteAccounts:
			accounts = bucketAncestorMap.get(-1, set())
			if len(accounts) > 0:
				accountStr = ", ".join(map(str, accounts))
				self.deleteTableRowsWhere("Buckets", SQL_WhereStatementBuilder("ID in (%s) OR Ancestor in (%s)" % (accountStr, accountStr)))
				self.deleteTransactionsWhere(SQL_WhereStatementBuilder("SourceBucket in (%s)" % accountStr).OR("DestBucket in (%s)" % accountStr))
			return accounts
		else:
			bucketList: Set[int] = set()
			for j in bucketAncestorMap.items():
				if j[0] != -1:
					for a in j[1]:
						bucketList.add(a)
					self.updateTableWhere("Transactions", {"SourceBucket": j[0]}, SQL_WhereStatementBuilder("SourceBucket in (%s)" % ", ".join(map(str, j[1]))))
					self.updateTableWhere("Transactions", {"DestBucket": j[0]}, SQL_WhereStatementBuilder("DestBucket in (%s)" % ", ".join(map(str, j[1]))))


			bucketStr = ", ".join(map(str, bucketList))
			self.deleteTableRowsWhere("Buckets", SQL_WhereStatementBuilder("ID in (%s)" % bucketStr))

			# This is an exception to the "Never delete transactions rule"
			# Transactions with a matching source and destination don't make any sense
			self.deleteTransactionsWhere(SQL_WhereStatementBuilder("SourceBucket == DestBucket"))

			return bucketList

class Bucket(SQL_RowMutable):
	def __init__(self, database: DatabaseWrapper, ID: int):
		super().__init__(database, "Buckets", ID)
	
	def getID(self) -> int:
		return asInt(self.getValue("ID"))
	
	def getName(self) -> str:
		return str(self.getValue("Name"))
	
	def getParent(self) -> Optional['Bucket']:
		parentID = asInt(self.getValue("Parent"))
		return cast(SpentDBManager, self.database).getBucket(parentID)

	def getAncestor(self) -> Optional['Bucket']:
		ancestorID = asInt(self.getValue("Ancestor"))
		return cast(SpentDBManager, self.database).getBucket(ancestorID)
	
class Account(Bucket):
	def getParent(self) -> Optional[Bucket]:
		return None
	
	def getParentAccount(self) -> 'Account':
		return self

	def getAncestor(self) -> Optional[Bucket]:
		return None
	
class Transaction(SQL_RowMutable):
	def __init__(self, database: DatabaseWrapper, ID: int):
		super().__init__(database, "Transactions", ID)
		
	def getID(self) -> int:
		return asInt(self.getValue("ID"))
	
	def getStatus(self) -> int:
		return asInt(self.getValue("Status"))
	
	def getTransactionDate(self) -> str:
		return str(self.getValue("TransDate"))
		
	def getPostDate(self) -> str:
		return str(self.getValue("PostDate"))
		
	def getAmount(self) -> str:
		return str(self.getValue("Amount"))
	
	def getMemo(self) -> str:
		return str(self.getValue("Memo"))

	def getPayee(self) -> str:
		return str(self.getValue("Payee"))
	
	def getSourceBucket(self) -> Optional[Bucket]:
		return cast(SpentDBManager, self.database).getBucket(asInt(self.getValue("SourceBucket")))
	
	def getDestBucket(self) -> Optional[Bucket]:
		return cast(SpentDBManager, self.database).getBucket(asInt(self.getValue("DestBucket")))
	
	def isTransfer(self) -> bool:
		return bool(self.getValue("IsTransfer"))
	
	def getType(self) -> int:
		return asInt(self.getValue("Type"))