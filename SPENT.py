from datetime import date
from sqlite3_DOM import *

def getCurrentDateStr():
	return str(date.today())

#TODO: The name of this class is not accurate. It should be called SpentDBManager or similar
#TODO: This class has a ton of duplicated code, the code reuse needs to be increased
#TODO: The creates should return the created object
#TODO: The singular "get's" should call the getWhere's

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
	
			source = (self.getValue("SourceBucket") != -1);
			dest = (self.getValue("DestBucket") != -1);
			if source and dest:
				#Transfer
				return 0
			elif not source and dest:
				#Deposit
				return 1
			elif source and not dest:
				#Withdrawal
				return 2
			
			return 3
		
		self.registerVirtualColumn("Transactions", "IsTransfer", checkIsTransfer)
		self.registerVirtualColumn("Transactions", "Type", getTransactionType)
		
		#Flag: These should be moved to util and/or be replaced by get**Where()
		def getBucketTransactions(source, tableName, columnName):
			return source.getTransactionsID()
		
		def getBucketChildren(source, tableName, columnName):
			return source.getChildrenID()
		
		def getAllBucketChildren(source, tableName, columnName):
			return source.getAllChildrenID()
		
		self.registerVirtualColumn("Buckets", "Transactions", getBucketTransactions)
		self.registerVirtualColumn("Buckets", "Children", getBucketChildren)
		self.registerVirtualColumn("Buckets", "AllChildren", getAllBucketChildren)
		#End Flag
		
	def createBucket(self, name, parent):
		#TODO: Verify the data is valid
		return self._tableInsertInto_("Buckets", 
									  {"Name" : str(name), 
									   "Parent" : int(parent)
									  })[0][0]
	
	def createTransaction(self, amount, status=0, sourceBucket=None, destBucket=None, transactionDate=getCurrentDateStr(), postDate=None, memo="",  payee=""):
		#TODO: Verify that all the data is in the correct format
		#print("%s - %s - %s - %s - %s - %s - %s - %s" % (amount, status, sourceBucket, destBucket, transactionDate, postDate, memo, payee))
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
	
	def createAccount(self, name):
		return self.createBucket(name, -1)
	
	def getBucket(self, bucketID):
		#TODO: Verify the id has a mapping
		if bucketID is not None: #TODO: and is an int
			result = self.selectTableRowsColumnsWhere("Buckets", ["Parent"], SQL_WhereStatementBuilder("ID == %d" % int(bucketID)))
			if result is None or len(result) < 1:
				print("Debug: AccountManager.getBucket: Returning None for id: %s with result %s" % (bucketID, result))
				return None

			if result[0].getValue("Parent") < 1:
				return Account(self, bucketID)
			return Bucket(self, bucketID)
		else:
			print("Error: AccountManager.getBucket: bucketID can't be None")
			return None
	
	def getBucketsWhere(self, where=None):
		nWhere = where
		if nWhere is not None:
			#TODO: To avoid ruining potentially complex where statements this would idealy insert at the begining of the where statement
			nWhere.insertStatement("AND", "Parent > -1")
		else:
			nWhere = SQL_WhereStatementBuilder("Parent > -1")
			
		result = self.selectTableRowsColumnsWhere("Buckets", ["ID"], nWhere)
		buckets = []
		for i in result:
			bucket = self.getBucket(i.getValue("ID"))
			if bucket is not None:
				buckets.append(bucket)
			else:
				print("Error: AccountManager.getBucketsWhere: Encountered a None bucket")
		return buckets
	
	def getTransaction(self, transactionID):
		#TODO: Verify the id has a mapping
		if transactionID is not None: #TOOD: and is an int
			return Transaction(self, transactionID)
		else:
			print("Error: AccountManager.getTransaction: transactionID can't be None")
			return None
		
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
			#TODO: To avoid ruining potentially complex where statements this would idealy insert at the begining of the where statement
			nWhere.insertStatement("AND", "Parent == -1")
		else:
			nWhere = SQL_WhereStatementBuilder("Parent == -1")
			
		result = self.selectTableRowsColumnsWhere("Buckets", ["ID"], nWhere)
		buckets = []
		for i in result:
			bucket = self.getBucket(i.getValue("ID"))
			if bucket is not None:
				buckets.append(bucket)
			else:
				print("Error: AccountManager.getAccountsWhere: Encountered a None bucket")
		return buckets
	
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
	
	def deleteBucketsWhere(self, where=None):
		pass
		
	def deleteTransaction(self, transaction):
		if transaction is not None: #TODO: and actually is a transaction
			if self.printDebug:
				print("Debug: AccountMan: Destroying Transaction: %s" % transaction)
			self.deleteTableRow("Transactions", int(transaction.getID()))
		else:
			print("Error: AccountManager.deleteTransaction: Transaction can't be None")
		del transaction # Destroy the data our reference points to; to prevent further use
		
	def deleteTransactionsWhere(self, where=None):
		pass
		
	def deleteAccount(self, account):
		self.deleteBucket(account)
		
	def deleteAccountsWhere(self, where=None):
		pass
		
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