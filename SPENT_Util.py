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
		
		def getAvailBucketBalance(source, tableName, columnName):
			return self.getAvailableBalance(source)

		def getPostedBucketBalance(source, tableName, columnName):
			return self.getPostedBalance(source)
		
		self._spentDB_.registerVirtualColumn("Buckets", "Balance", getAvailBucketBalance)
		self._spentDB_.registerVirtualColumn("Buckets", "PostedBalance", getPostedBucketBalance)

	def getPostedBalance(self, bucket):
		return self._calculateBalance_(bucket, True)
		
	def getAvailableBalance(self, bucket):
		return self._calculateBalance_(bucket)
		
	def _calculateBalance_(self, bucket, posted=False):
		ids = bucket.getAllChildrenID()
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
	