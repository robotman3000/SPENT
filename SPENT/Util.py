from typing import Set, cast, List, Any, Optional, Dict
from SPENT.SPENT_Schema_v1_1 import *
from SPENT.SQLIB import SQL_WhereStatementBuilder

class SpentUtil:
	@classmethod
	def getPostedBalance(self, connection, bucket: 'Bucket', includeChildren: bool = False) -> float:
		return self._calculateBalance_(connection, bucket, True, includeChildren)

	@classmethod
	def getAvailableBalance(self, connection, bucket: 'Bucket', includeChildren: bool = False) -> float:
		return self._calculateBalance_(connection, bucket, False, includeChildren)

	@classmethod
	def _calculateBalance_(self, connection, bucket: 'Bucket', posted: bool = False, includeChildren: bool = False) -> float:
		ids = []
		if includeChildren:
			ids = self.getAllBucketChildrenID(connection, bucket)
		ids.append(bucket.getID())  # We can't forget ourself
		idStr = ", ".join(map(str, ids))

		statusStr = ""
		if posted:
			statusStr = "AND Status > 2"

		query = "SELECT IFNULL(SUM(Amount), 0) AS \"Amount\" FROM (SELECT -1*SUM(Amount) AS \"Amount\" FROM Transactions WHERE SourceBucket IN (%s) %s AND Status != 0 UNION ALL SELECT SUM(Amount) AS \"Amount\" FROM Transactions WHERE DestBucket IN (%s) %s AND Status != 0)" % (
		idStr, statusStr, idStr, statusStr)
		column = "Amount"

		result = connection.execute(query)
		if len(result) > 0:
			return round(float(result[0][column]), 2)
		return 0

	@classmethod
	def getBucketParentAccount(self, bucket: 'Bucket') -> 'Bucket':
		# Do not reimplement this to use ancestor. This function is needed to generate the ancestor ID
		parent = bucket.getParent()
		if parent is None:
			return bucket
		elif parent.getID() == -1:
			return parent

		return self.getBucketParentAccount(parent)

	@classmethod
	def getBucketChildren(self, connection, bucket: 'Bucket') -> List['Bucket']:
		#print(type(bucket))
		buckets = EnumBucketsTable.select(connection, SQL_WhereStatementBuilder("%s == %d" % ("Parent", int(bucket.getID()))))
		return buckets

	@classmethod
	def getBucketChildrenID(self, connection, bucket: 'Bucket') -> List[int]:
		# TODO: this and the "all" version are inefficent
		return self.getBucketChildren(connection, bucket).getValues(EnumBucketsTable.id)

	@classmethod
	def getAllBucketChildren(self, connection, bucket: 'Bucket') -> List['Bucket']:
		childrenSelection = self.getBucketChildren(connection, bucket)
		children: List[Bucket] = list(childrenSelection.getRows().values())
		for i in childrenSelection:
			children += self.getAllBucketChildren(connection, i)

		# print(newChildren)
		return children

	@classmethod
	def getAllBucketChildrenID(self, connection, bucket: 'Bucket') -> List[int]:
		return [i.getID() for i in self.getAllBucketChildren(connection, bucket)]

	@classmethod
	def getBucketTransactions(self, connection, bucket: 'Bucket') -> List['Transaction']:
		transactions = EnumTransactionTable.select(connection, SQL_WhereStatementBuilder("%s == %s" % ("SourceBucket", bucket.getID())).OR(
				"%s == %s" % ("DestBucket", bucket.getID())))
		return transactions

	@classmethod
	def getBucketTransactionsID(self, connection, bucket: 'Bucket') -> List[int]:
		return [i.getID() for i in self.getBucketTransactions(connection, bucket)]

	@classmethod
	def getAllBucketTransactions(self, connection, bucket: 'Bucket') -> List['Transaction']:
		allIDList = ", ".join(map(str, self.getAllBucketChildrenID(connection, bucket) + [bucket.getID()]))
		result = EnumTransactionTable.select(connection,
			SQL_WhereStatementBuilder("%s IN (%s)" % ("SourceBucket", allIDList)).OR(
				"%s IN (%s)" % ("DestBucket", allIDList)))
		return result

	@classmethod
	def getAllBucketTransactionsID(self, connection, bucket: 'Bucket') -> List[int]:
		return [i.getID() for i in self.getAllBucketTransactions(connection, bucket)]
