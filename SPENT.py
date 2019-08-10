from datetime import date
from sqlite3_DOM import *

def getCurrentDateStr():
	return str(date.today())

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
		
		def getAvailBucketBalance(source, tableName, columnName):
			return source.getAvailableBalance()
			
		def getPostedBucketBalance(source, tableName, columnName):
			return source.getPostedBalance()
		
		def getBucketTransactions(source, tableName, columnName):
			return source.getTransactionsID()
		
		def getBucketChildren(source, tableName, columnName):
			return source.getChildrenID()
		
		def checkIsTransfer(source, tableName, columnName):
			return source.isTransfer()
		
		self.registerVirtualColumn("Buckets", "Balance", getAvailBucketBalance)
		self.registerVirtualColumn("Buckets", "PostedBalance", getPostedBucketBalance)
		self.registerVirtualColumn("Buckets", "Transactions", getBucketTransactions)
		self.registerVirtualColumn("Buckets", "Children", getBucketChildren)
		#self.registerVirtualColumn("Transactions", "IsTransfer", checkIsTransfer)
		
	def createBucket(self, name, parent):
		#TODO: Verify the data is valid
		return self._tableInsertInto_("Buckets", 
									  {"Name" : str(name), 
									   "Parent" : int(parent)
									  })[0]
	
	def createTransaction(self, amount, status=0, sourceBucket=None, destBucket=None, transactionDate=getCurrentDateStr(), postDate=None, memo="",  payee=""):
		#TODO: Verify that all the data is in the correct format
		print("%s - %s - %s - %s - %s - %s - %s - %s" % (amount, status, sourceBucket, destBucket, transactionDate, postDate, memo, payee))
		return self._tableInsertInto_("Transactions", 
									  {"Status" : int(status),
									   "TransDate" : str(transactionDate),
									   "PostDate" : str(postDate),
									   "Amount" : float(amount),
									   "SourceBucket" : int(-1 if sourceBucket is None else sourceBucket.getID()),
									   "DestBucket" : int(-1 if destBucket is None else destBucket.getID()),
									   "Memo" : str(memo),
									   "Payee": str(payee)
									  })[0]

	def getBucket(self, bucketID):
		#TODO: Verify the id actually has a mapping
		if bucketID is not None: #TODO: and is an int
			result = self.selectTableRowsColumnsWhere("Buckets", ["Parent"], SQL_WhereStatementBuilder("ID == %d" % int(bucketID)))
			if result is None or len(result) < 1:
				print("Debug: AccountManager.getBucket: Returning None for id: %s wit result %s" % (bucketID, result))
				return None

			if result[0].getValue("Parent") < 1:
				return Account(self, bucketID)
			return Bucket(self, bucketID)
		else:
			print("Error: AccountManager.getBucket: bucketID can't be None")
			return None
		
	def getTransaction(self, transactionID):
		#TODO: Verify the id has a mapping
		if transactionID is not None: #TOOD: and is an int
			return Transaction(self, transactionID)
		else:
			print("Error: AccountManager.getTransaction: transactionID can't be None")
			return None
		
	def deleteBucket(self, bucket):
		if bucket is not None: #TODO: and actually is a bucket
			isAccount = (bucket.getParent() == None)
			# We save this outside the loop because all the affected transactions share the same parent already
			parentAccount = None
			for trans in (bucket.getAllTransactions() if isAccount else bucket.getTransactions()):
				print("IsAccount %s - %s, %s" % (bucket.getID(), isAccount, trans.getID()))
				if isAccount:
					# If the bucket is an account then delete the transactions
					self.deleteTransaction(trans)
				else:
					# If the bucket is a bucket then set the "bucket" of all affected transactions to the "account" bucket
					if parentAccount is None:
						parentAccount = trans.getBucket().getParentAccount()
					trans.updateValue("Bucket", parentAccount.getID())
					if trans.getTransferID() != -1:
						self.deleteTransaction(trans)

			for c in bucket.getChildren():
				self.deleteBucket(c)

			if self.printDebug:
				print("Debug: AccountMan: Destroying Bucket: %s" % bucket)
			self.deleteTableRow("Buckets", int(bucket.getID()))
		else:
			print("Error: AccountManager.getBucketList: Bucket can't be None")
		del bucket # Destroy the data our reference points to; to prevent further use
		
	def deleteTransaction(self, transaction):
		if transaction is not None: #TODO: and actually is a transaction
			if self.printDebug:
				print("Debug: AccountMan: Destroying Transaction: %s" % transaction)
			self.deleteTableRow("Transactions", int(transaction.getID()))
		else:
			print("Error: AccountManager.deleteTransaction: Transaction can't be None")
		del transaction # Destroy the data our reference points to; to prevent further use
	
	def getAccountList(self):
		return self._getBucketsList_(SQL_WhereStatementBuilder("Parent == -1"))
		
	def getBucketList(self):
		return self._getBucketsList_(SQL_WhereStatementBuilder("Parent > -1"))
	
	def _getBucketsList_(self, where):
		result = self.selectTableRowsColumnsWhere("Buckets", ["ID"], where)
		buckets = []
		for i in result:
			bucket = self.getBucket(i.getValue("ID"))
			if bucket is not None:
				buckets.append(bucket)
			else:
				print("Error: AccountManager.getTransactionList: Encountered a None transaction")
		return buckets
		
	def getTransactionList(self):
		result = self.selectTableRowsColumns("Transactions", columnNames=["ID"])
		transactions = []
		for i in result:
			trans = self.getTransaction(i.getValue("ID"))
			if trans is not None:
				transactions.append(trans)
			else:
				print("Error: AccountManager.getTransactionList: Encountered a None transaction")
		return transactions	

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
	
	def getParentAccount(self):
		parent = self.getParent()
		if parent.getID() == -1:
			return parent
		
		return parent.getParentAccount()
	
	def getChildren(self):
		result1 = self.database.selectTableRowsColumnsWhere(self.getTableName(), ["ID"], SQL_WhereStatementBuilder("%s == %d" % ("Parent", int(self.getID()))))
		children = []
		for i in result1:
			bucket = self.database.getBucket(i.getValue("ID"))
			if bucket is not None:
				children.append(bucket)
			else:
				print("Error: Bucket.getChildren: bucket id %s returned None" % i.getValue("ID"))
		return children
	
	def getChildrenID(self):
		#TODO: this and the "all" version are inefficent
		return [i.getID() for i in self.getChildren()]
	
	def getAllChildren(self):
		children = self.getChildren()
		newChildren = [] + children
		for i in children:
			newChildren += i.getAllChildren()
			
		#print(newChildren)
		return newChildren
	
	def getAllChildrenID(self):
		return [i.getID() for i in self.getAllChildren()]
	
	def getTransactions(self):
		return self._getTransactions_([self.getID()])
		
	def getTransactionsID(self):
		return self._getTransactions_([self.getID()], False)
	
	def getAllTransactions(self):
		return self._getTransactions_(self.getAllChildrenID() + [self.getID()])
	
	def getAllTransactionsID(self):
		return self._getTransactions_(self.getAllChildrenID() + [self.getID()], False)
	
	def getPostedBalance(self):
		return self._calculateBalance_(True)
		
	def getAvailableBalance(self):
		return self._calculateBalance_()
		
	def _calculateBalance_(self, posted=False):
		ids = self.getAllChildrenID()
		ids.append(self.getID()) # We can't forget ourself
		idStr = ", ".join(map(str, ids))
		
		statusStr = ""
		if posted:
			statusStr = "AND Status IN (2, 3)"
		
		query = "SELECT IFNULL(SUM(Amount), 0) AS \"Amount\" FROM (SELECT -1*SUM(Amount) AS \"Amount\" FROM Transactions WHERE SourceBucket IN (%s) %s UNION ALL SELECT SUM(Amount) AS \"Amount\" FROM Transactions WHERE DestBucket IN (%s) %s)" % (idStr, statusStr, idStr, statusStr)
		column = "Amount"
		#print("Balance Query: %s" % query)
		result = self.database._rawSQL_(query)
		rows = self.database.parseRows(result, [column], "Transactions")
		if len(rows) > 0:
			return round(float(rows[0].getValue(column, False)), 2)
		return 0
	
	def _getTransactions_(self, bucketIDs, asTransactions=True):
		#TODO: Verify input data
		idStr = ", ".join(map(str, bucketIDs))
		query = "SELECT ID FROM \"Transactions\" WHERE SourceBucket IN (%s) or DestBucket IN (%s) ORDER BY ID" % (idStr, idStr)		
		result = self.database.parseRows(self.database._rawSQL_(query), ["ID"], "Transactions")
		#print("Res: %s" % result)
		return [(self.database.getTransaction(i.getValue("ID")) if asTransactions else i.getValue("ID")) for i in result]
		
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
		return (self.getSourceBucket() is not None) and (self.getDestBucket() is not None)
