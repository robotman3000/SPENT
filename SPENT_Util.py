#Verb layer features
#	Reconcile
#	Import/Export
#	Report Generation
#	Account/Bucket Balance Calculation

#Transaction Tagging
#Transaction Grouping?

from SPENT import *

class SPENTUtil():
	def __init__(self, spentDB):
		self._spentDB_ = spentDB
		
	def registerUtilityColumns(self):
		def getAvailBucketBalance(source, tableName, columnName):
			return self.getAvailableBalance(source)

		def getPostedBucketBalance(source, tableName, columnName):
			return self.getPostedBalance(source)
		
		self._spentDB_.registerVirtualColumn("Buckets", "Balance", getAvailBucketBalance)
		self._spentDB_.registerVirtualColumn("Buckets", "PostedBalance", getPostedBucketBalance)

		
		#TODO: SHould these vir columns be kept around?
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
		
	def getPostedBalance(self, bucket):
		return self._calculateBalance_(bucket, True)
		
	def getAvailableBalance(self, bucket):
		return self._calculateBalance_(bucket)
		
	def _calculateBalance_(self, bucket, posted=False):
		ids = self.getAllBucketChildrenID(bucket)
		ids.append(bucket.getID()) # We can't forget ourself
		idStr = ", ".join(map(str, ids))
	
		statusStr = ""
		if posted:
			statusStr = "AND Status IN (2, 3)"
	
		query = "SELECT IFNULL(SUM(Amount), 0) AS \"Amount\" FROM (SELECT -1*SUM(Amount) AS \"Amount\" FROM Transactions WHERE SourceBucket IN (%s) %s UNION ALL SELECT SUM(Amount) AS \"Amount\" FROM Transactions WHERE DestBucket IN (%s) %s)" % (idStr, statusStr, idStr, statusStr)
		column = "Amount"
		
		result = self._spentDB_._rawSQL_(query)
		rows = self._spentDB_.parseRows(result, [column], "Transactions")
		if len(rows) > 0:
			return round(float(rows[0].getValue(column, False)), 2)
		return 0
	
	def getBucketParentAccount(self, bucket):
		parent = bucket.getParent()
		if parent.getID() == -1:
			return parent
		
		return self.getBucketParentAccount(parent)

	def getBucketChildren(self, bucket):
		return self._spentDB_.getBucketsWhere(SQL_WhereStatementBuilder("%s == %d" % ("Parent", int(bucket.getID()))))
	
	def getBucketChildrenID(self, bucket):
		#TODO: this and the "all" version are inefficent
		return [i.getID() for i in self.getBucketChildren(bucket)]
	
	def getAllBucketChildren(self, bucket):
		children = self.getBucketChildren(bucket)
		newChildren = [] + children
		for i in children:
			newChildren += self.getAllBucketChildren(i)
			
		#print(newChildren)
		return newChildren
	
	def getAllBucketChildrenID(self, bucket):
		return [i.getID() for i in self.getAllBucketChildren(bucket)]
	
	def getBucketTransactions(self, bucket):
		return self._spentDB_.getTransactionsWhere(SQL_WhereStatementBuilder("%s == %s" % ("SourceBucket", bucket.getID())).OR("%s == %s" % ("DestBucket", bucket.getID())))
		
	def getBucketTransactionsID(self, bucket):
		return [i.getID() for i in self.getBucketTransactions(bucket)]
	
	def getAllBucketTransactions(self, bucket):
		allIDList = ", ".join(map(str, self.getAllBucketChildrenID(bucket) + [bucket.getID()]))
		return self._spentDB_.getTransactionsWhere(SQL_WhereStatementBuilder("%s IN (%s)" % ("SourceBucket", allIDList)).OR("%s IN (%s)" % ("DestBucket", allIDList)))
	
	def getAllBucketTransactionsID(self, bucket):
		return [i.getID() for i in self.getAllBucketTransactions(bucket)]