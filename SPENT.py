from datetime import date
from sqlite3_DOM import *

def getCurrentDateStr():
	return str(date.today())

#TODO: The name of this class is not accurate. It should be called SpentDBManager or similar
class AccountManager(DatabaseWrapper):
	def __init__(self, dbFile="SPENT.db"):
		super().__init__(dbFile)
		self.registerTableSchema("Buckets", 
			[{"name": "ID", "type": "INTEGER", "PreventNull": True, "IsPrimaryKey": True, "AutoIncrement": True, "KeepUnique": True},
			 {"name": "Name", "type": "TEXT", "PreventNull": True, "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": True},
			 {"name": "Parent", "type": "INTEGER", "remapKey": "Buckets:ID:Name", "PreventNull": True, "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": False}])

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
		
	def createBucket(self, name, parent):
		#TODO: Verify the data is valid
		return self.getBucket(self._tableInsertInto_("Buckets", 
									  {"Name" : str(name), 
									   "Parent" : int(parent)
									  })[0][0])
	
	def createTransaction(self, amount, status=0, sourceBucket=None, destBucket=None, transactionDate=getCurrentDateStr(), postDate=None, memo="",  payee=""):
		#TODO: Verify that all the data is in the correct format
		#print("%s - %s - %s - %s - %s - %s - %s - %s" % (amount, status, sourceBucket, destBucket, transactionDate, postDate, memo, payee))
		return self.getTransaction(self._tableInsertInto_("Transactions", 
									  {"Status" : int(status),
									   "TransDate" : str(transactionDate),
									   "PostDate" : str(postDate),
									   "Amount" : float(amount),
									   "SourceBucket" : int(-1 if sourceBucket is None else sourceBucket.getID()),
									   "DestBucket" : int(-1 if destBucket is None else destBucket.getID()),
									   "Memo" : str(memo),
									   "Payee": str(payee)
									  })[0][0])
	
	def createAccount(self, name):
		return self.createBucket(name, -1)
	
	def getBucket(self, bucketID):
		if bucketID > -1:
			bucket = Bucket(self, bucketID)
			if bucket.getParent() == -1:
				return Account(bucket)
			return bucket
		return None

	def getBucketsWhere(self, where=None):
		nWhere = where
		if nWhere is not None:
			nWhere.insertStatement("AND", "Parent > -1")
		else:
			nWhere = SQL_WhereStatementBuilder("Parent > -1")
		return self._getBucketsWhere_(nWhere)
	
	def getTransaction(self, transactionID):
		return Transaction(self, transactionID)
		
	def getTransactionsWhere(self, where=None):
		result = self.selectTableRowsColumnsWhere("Transactions", columnNames=["ID"], where=where)
		transactions = []
		for i in result:
			trans = self.getTransaction(i.getValue("ID"))
			if trans is not None:
				transactions.append(trans)
			else:
				print("Error: AccountManager.getTransactionsWhere: Encountered a None transaction")
		return transactions	
	
	def getAccount(self, accountID):
		return self.getBucket(accountID)
		
	def getAccountsWhere(self, where=None):
		nWhere = where
		if nWhere is not None:
			nWhere.insertStatement("AND", "Parent == -1")
		else:
			nWhere = SQL_WhereStatementBuilder("Parent == -1")
		return self._getBucketsWhere_(nWhere)
	
	def deleteBucket(self, bucket):
		where = self.rowsToWhere(bucket)
		self.deleteBucketsWhere(where)
		del bucket # Destroy the data our reference points to; to prevent further use
	
	def deleteBucketsWhere(self, where):
		if where is None:
			raise ValueError("AccountManager.deleteBucketsWhere: where can't be None")
			
		util = SPENT_Util.SPENTUtil(self)
		buckets = self._getBucketsWhere_(where)
		
		bucketIDs = Set()
		for bucket in buckets:
			children = util.getAllBucketChildrenID(bucket)
			for i in children:
				bucketIDs.add(i)
			bucketIDs.add(bucket.getID())
		
		bucketStr = ", ",join(bucketIDs)
		self.deleteTransactionsWhere(SQL_WhereStatementBuilder("SourceBucket in (%s)" % bucketStr).OR("DestBucket in (%s)" % bucketStr))
		self.deleteTableRowsWhere("Buckets", SQL_WhereStatementBuilder("ID in (%s)" % bucketStr))
		
	def deleteTransaction(self, transaction):
		where = self.rowsToWhere(transaction)
		self.deleteTransactionsWhere(where)
		del transaction # Destroy the data our reference points to; to prevent further use
		
	def deleteTransactionsWhere(self, where):
		if where is None:
			raise ValueError("AccountManager.deleteTransactionsWhere: where can't be None")
		self.deleteTableRowsWhere("Transactions", where)
		
	def deleteAccount(self, account):
		self.deleteBucket(account)
		
	def deleteAccountsWhere(self, where):
		self.deleteBucketsWhere(where)
	
	def _getBucketsWhere_(self, where):
		result = self.selectTableRowsColumnsWhere("Buckets", ["ID"], where)
		buckets = []
		for i in result:
			bucket = self.getBucket(i.getValue("ID"))
			if bucket is not None:
				buckets.append(bucket)
			else:
				print("Error: AccountManager._getBucketsWhere_: Encountered a None bucket")
		return buckets
		
class Bucket(SQL_RowMutable):
	def __init__(self, database, ID):
		super().__init__(database, "Buckets", ID)
	
	def getID(self):
		return self.getValue("ID")
	
	def getName(self):
		return self.getValue("Name")
	
	def getParent(self):
		parentID = self.getValue("Parent")
		return self.database.getBucket(parentID)
	
class Account(Bucket):
	def getParent(self):
		return None
	
	def getParentAccount(self):
		return self
	
class Transaction(SQL_RowMutable):
	def __init__(self, database, ID):
		super().__init__(database, "Transactions", ID)
		
	def getID(self):
		return self.getValue("ID")
	
	def getStatus(self):
		return self.getValue("Status")
	
	def getTransactionDate(self):
		return self.getValue("TransDate")
		
	def getPostDate(self):
		return self.getValue("PostDate")
		
	def getAmount(self):
		return self.getValue("Amount")
	
	def getMemo(self):
		return self.getValue("Memo")

	def getPayee(self):
		return self.getValue("Payee")
	
	def getSourceBucket(self):
		return self.database.getBucket(self.getValue("SourceBucket"))
	
	def getDestBucket(self):
		return self.database.getBucket(self.getValue("DestBucket"))
	
	def isTransfer(self):
		return self.getValue("IsTransfer")
	
	def getType(self):
		return self.getValue("Type")