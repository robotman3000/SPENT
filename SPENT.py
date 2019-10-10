from datetime import date
from sqlite3_DOM import *
from SPENT_Util import *

def getCurrentDateStr():
	return str(date.today())

#TODO: The name of this class is not accurate. It should be called SpentDBManager or similar
class AccountManager(DatabaseWrapper):
	def __init__(self, dbFile="SPENT.db"):
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
		return self._deleteBucketsWhere_(where, False)
		
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
		self._deleteBucketsWhere_(where, True)
	
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

	def _deleteBucketsWhere_(self, where, deleteAccounts):
		#TODO: This should be rewriten to use less SQL queries

		if where is None:
			raise ValueError("AccountManager._deleteBucketsWhere_: where can't be None")

		util = SPENTUtil(self)
		buckets = self._getBucketsWhere_(where)

		bucketAncestorMap = {}
		for bucket in buckets:
			bucketIDs = bucketAncestorMap.get(bucket.getAncestor(), set())
			bucketIDs.add(bucket.getID())

			# We don't want the children of an account in the list of accounts
			if bucket.getAncestor() is not None:
				children = util.getAllBucketChildrenID(bucket)
				for i in children:
					bucketIDs.add(i)

		bucketList = []
		for i in bucketAncestorMap.items():
			if i[0] is not None: # None is used as a key
				bucketList += i[1]
				self.updateTableWhere("Transactions", "SourceBucket = %s" % i[0], SQL_WhereStatementBuilder("SourceBucket in (%s)" % ", ".join(map(str, i[1]))))
				self.updateTableWhere("Transactions", "DestBucket = %s" % i[0], SQL_WhereStatementBuilder("DestBucket in (%s)" % ", ".join(map(str, i[1]))))

				# This is an exception to the "Never delete transactions rule"
				# Transactions with a matching source and destination don't make any sense
				self.deleteTransactionsWhere(SQL_WhereStatementBuilder("SourceBucket == DestBucket"))

		bucketStr = ", ".join(map(str, bucketList))
		self.deleteTableRowsWhere("Buckets", SQL_WhereStatementBuilder("ID in (%s)" % bucketStr))

		if deleteAccounts:
			accounts = bucketAncestorMap.get(None, set())
			if len(accounts) > 0:
				accountStr = ", ".join(map(str, accounts))
				self.deleteTableRowsWhere("Buckets", SQL_WhereStatementBuilder("ID in (%s)" % accountStr))
				self.deleteTransactionsWhere(SQL_WhereStatementBuilder("SourceBucket in (%s)" % accountStr).OR("DestBucket in (%s)" % accountStr))

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

	def getAncestor(self):
		ancestorID = self.getValue("Ancestor")
		return self.database.getBucket(ancestorID)
	
class Account(Bucket):
	def getParent(self):
		return None
	
	def getParentAccount(self):
		return self

	def getAncestor(self):
		return None
	
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