#Verb layer features
#	Reconcile
#	Import/Export
#	Report Generation
#	Account/Bucket Balance Calculation

#Transaction Tagging
#Transaction Grouping?

from SPENT import *

class SPENT():
	def __init__(self, spentDB):
		self._spentDB_ = spentDB
		
	#Begin Flag
#	def getPostedBalance(self):
#		return self._calculateBalance_(True)
#		
#	def getAvailableBalance(self):
#		return self._calculateBalance_()
#		
#	def _calculateBalance_(self, posted=False):
#		ids = self.getAllChildrenID()
#		ids.append(self.getID()) # We can't forget ourself
#		idStr = ", ".join(map(str, ids))
		
#		statusStr = ""
#		if posted:
#			statusStr = "AND Status IN (2, 3)"
		
#		query = "SELECT IFNULL(SUM(Amount), 0) AS \"Amount\" FROM (SELECT -1*SUM(Amount) AS \"Amount\" FROM Transactions WHERE SourceBucket IN (%s) %s UNION ALL SELECT SUM(Amount) AS \"Amount\" FROM Transactions WHERE DestBucket IN (%s) %s)" % (idStr, statusStr, idStr, statusStr)
#		column = "Amount"
		#print("Balance Query: %s" % query)
#		result = self.database._rawSQL_(query)
#		rows = self.database.parseRows(result, [column], "Transactions")
#		if len(rows) > 0:
#			return round(float(rows[0].getValue(column, False)), 2)
#		return 0
	#End Flag	
	
	
		def getAvailBucketBalance(source, tableName, columnName):
			return source.getAvailableBalance()
			
		def getPostedBucketBalance(source, tableName, columnName):
			return source.getPostedBalance()
		self.registerVirtualColumn("Buckets", "Get Avail Bal", checkIsTransfer)
		self.registerVirtualColumn("Buckets", "Get Posted Bal", checkIsTransfer)
	