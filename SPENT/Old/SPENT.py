from datetime import date
from SPENT.SQLIB import *
from SPENT.SPENT_Schema_v1 import *
from typing import Set, cast, List, Any, Optional, Dict

#Verb layer features
#	Reconcile
#	Import/Export
#	Report Generation
#	Account/Bucket Balance Calculation

#Transaction Tagging
#Transaction Grouping?

def getCurrentDateStr() -> str:
	return str(date.today())

class TagManager:
	def __init__(self, database: 'SpentDBManager'):
		self.db = database

	def getTransactionTags(self, connection, transaction: 'Transaction') -> List['Tag']:
		return self.getTagsWhere(connection, SQL_WhereStatementBuilder("TransactionID == %d" % transaction.getID()))

	def getTag(self, connection, id: int) -> Optional['Tag']:
		return EnumTagsTable.getRow(connection, id)

	#TODO: Implement a getTag by name

	def getTagsWhere(self, connection, where: Optional[SQL_WhereStatementBuilder] = None) -> List['Tag']:
		if where is None:
			where = SQL_WhereStatementBuilder()


		result = EnumTagsTable.select(connection, where)
		#result = self.db.selectTableRowsColumnsWhere("Tags", columnNames=["ID"], where=where)
		tags = []
		for i in result:
			tag = self.getTag(int(i.getID()))
			if tag is not None:
				tags.append(tag)
			else:
				print("Error: TagManager.getTagsWhere: Encountered a None tag")
		return tags

	def createTag(self, connection, name: str) -> Optional['Tag']:
		return EnumTagsTable.createRow(connection, {"Name": str(name)})

	def deleteTag(self, connection, tag: 'Tag') -> None:
		return EnumTagsTable.deleteRow(connection, tag.getID())
		del tag

	def deleteTagsWhere(self, connection, where: SQL_WhereStatementBuilder) -> List[int]:
		tags = self.getTagsWhere(connection, where)
		tagIDs = []
		for tag in tags:
			tagIDs.append(tag.getID())
			self.removeTagFromTransactions(connection, tag.getTransactions(), tag)
		deleteSel = EnumTagsTable.select(connection, where)
		deleteSel.deleteRows()
		return tagIDs

	def getTagTransactions(self, connection) -> List['Transaction']:
		transSel = EnumTransactionTagsTable.select(connection, SQL_WhereStatementBuilder(
																 "TagID == %d" % self.getID()))
		transListSel = EnumTransactionTable.select(connection, SQL_WhereStatementBuilder(
			"ID in (%s)" % ", ".join([str(row.getValue(EnumTransactionTagsTable.TransactionID)) for row in transSel.getRowIDs()])))
		return transListSel

	def applyTagToTransactions(self, connection, transactions, tag) -> None:
		myID = tag.getID()  # No need to query the table N > 1 times for the same thing, once will do
		for t in transactions:
			EnumTransactionTagsTable.createRow(connection, {EnumTransactionTagsTable.TransactionID: t.getID(), EnumTransactionTagsTable.TagID: myID})

	def removeTagFromTransactions(self, connection, transactions: List['Transaction'], tag) -> None:
		idList = [str(t.getID()) for t in transactions if t is not None]
		if len(idList) > 0:
			where = SQL_WhereStatementBuilder("TagID == %s" % tag.getID()).AND(
				"TransactionID in (%s)" % ", ".join(idList))
			delSel = EnumTransactionTagsTable.select(where)
			delSel.deleteRows()

class SpentDBManager():
	def createBucket(self, connection, name: str, parent: int) -> Optional['Bucket']:
		ancestor = -1
		if int(parent) != -1:
			par = self.getBucket(int(parent))
			if par is None:
				ancestor = parent
			else:
				ancestor = self.util.getBucketParentAccount(par).getID()

		e = EnumBucketsTable
		return EnumBucketsTable.createRow(connection, {e.Name : name,
                                       e.Parent : parent,
                                       e.Ancestor : ancestor,
                                      })
	
	def createTransaction(self, connection, amount: float, status: int = 0, sourceBucket: Optional['Bucket'] = None, destBucket: Optional['Bucket'] = None, transactionDate: Optional[str] = None, postDate: Optional[str] = None, memo: str = "",  payee: str = "", group: int = -1) -> 'Transaction':
		e = EnumTransactionTable
		return EnumTransactionTable.createRow(connection, {e.Status : int(status),
									   e.TransDate : getCurrentDateStr() if transactionDate is None else str(transactionDate),
									   e.PostDate : postDate,
									   e.Amount : float(amount),
									   e.SourceBucket : int(-1 if sourceBucket is None else sourceBucket.getID()),
									   e.DestBucket : int(-1 if destBucket is None else destBucket.getID()),
									   e.Memo : str(memo),
									   e.Payee : str(payee),
									   e.GroupID: int(group)
									  })
	
	def createAccount(self, connection, name: str) -> Optional['Bucket']: # TODO: This should return account
		return self.createBucket(connection, name, -1)

	def createTransactionGroup(self, connection, memo: str, bucket: Optional['Bucket']) -> Optional['TransactionGroup']:
		e = EnumTransactionGroupsTable
		return EnumTransactionGroupsTable.createRow(connection,
										{e.Bucket : int(-1 if bucket is None else bucket.getID()),
										 e.Memo: str(memo),
										   })

	def getBucket(self, connection, bucketID: int) -> Optional['Bucket']:
		return EnumBucketsTable.getRow(connection, bucketID)

	def getBucketsWhere(self, connection, where: Optional[SQL_WhereStatementBuilder] = None) -> List['Bucket']:
		nWhere = where
		if nWhere is not None:
			nWhere.insertStatement("AND", "Parent > -1")
		else:
			nWhere = SQL_WhereStatementBuilder("Parent > -1")
		return self._getBucketsWhere_(connection, nWhere)
	
	def getTransaction(self, connection, transactionID: int) -> 'Transaction':
		return EnumTransactionTable.getRow(connection, transactionID)
		
	def getTransactionsWhere(self, connection, where: Optional[SQL_WhereStatementBuilder] = None) -> RowSelection:
		return EnumTransactionTable.select(connection, where)

	def getTransactionGroup(self, connection, groupID: int) -> Optional['TransactionGroup']:
		# TODO: Use the (to be implemented) constraints system to enforce an id > -1
		if groupID < 0:
			return None
		return EnumTransactionGroupsTable.getRow(connection, groupID)

	def getTransactionGroupsWhere(self, connection, where: Optional[SQL_WhereStatementBuilder] = None) -> List['TransactionGroup']:
		return EnumTransactionGroupsTable.select(connection, where)

	def getAccount(self, connection, accountID: int) -> Optional['Bucket']: #TODO: This should be marked to return account
		return self.getBucket(connection, accountID)
		
	def getAccountsWhere(self, connection, where: Optional[SQL_WhereStatementBuilder] = None) -> List['Bucket']: #TODO: This should be marked to return accounts
		nWhere = where
		if nWhere is not None:
			nWhere.insertStatement("AND", "Parent == -1")
		else:
			nWhere = SQL_WhereStatementBuilder("Parent == -1")
		return self._getBucketsWhere_(connection, nWhere)
	
	def deleteBucket(self, connection, bucket: 'Bucket') -> None:
		EnumBucketsTable.deleteRow(connection, bucket.getRowID())
		del bucket # Destroy the data our reference points to; to prevent further use
	
	def deleteBucketsWhere(self, connection, where: SQL_WhereStatementBuilder) -> Set[int]:
		return self._deleteBucketsWhere_(connection, where, False)
		
	def deleteTransaction(self, connection, transaction: 'Transaction') -> None:
		EnumTransactionTable.deleteRow(connection, transaction.getRowID())
		del transaction # Destroy the data our reference points to; to prevent further use
		
	def deleteTransactionsWhere(self, connection, where: SQL_WhereStatementBuilder):#TODO return List[int]
		if where is None:
			raise ValueError("SpentDBManager.deleteTransactionsWhere: where can't be None")
		selection = EnumTransactionTable.select(connection, where)
		selection.deleteRows()

	def deleteTransactionGroup(self, connection, group: 'TransactionGroup') -> None:
		EnumTransactionGroupsTable.deleteRow(connection, group.getRowID())
		del group  # Destroy the data our reference points to; to prevent further use

	def deleteTransactionGroupsWhere(self, connection, where: SQL_WhereStatementBuilder):  # TODO return List[int]
		if where is None:
			raise ValueError("SpentDBManager.deleteTransactionGroupsWhere: where can't be None")
		selection = EnumTransactionGroupsTable.select(connection, where)
		selection.deleteRows()

	def deleteAccount(self, connection, account: 'Account') -> None:
		EnumBucketsTable.deleteRow(connection, account.getRowID())
		del account  # Destroy the data our reference points to; to prevent further use
		
	def deleteAccountsWhere(self, connection, where: SQL_WhereStatementBuilder) -> Set[int]:
		return self._deleteBucketsWhere_(connection, where, True)
	
	def _getBucketsWhere_(self, connection, where: SQL_WhereStatementBuilder) -> List['Bucket']:
		return EnumBucketsTable.select(connection, where)

	def _deleteBucketsWhere_(self, connection, where: SQL_WhereStatementBuilder, deleteAccounts: bool) -> Set[int]:
		#TODO: This should be rewriten to use less SQL queries

		if where is None:
			raise ValueError("SpentDBManager._deleteBucketsWhere_: where can't be None")
		bucketSelection = EnumBucketsTable.select(connection, where)
		bucketAncestorMap: Dict[int, Set[int]] = {}
		for bucket in bucketSelection:
			ancestor = bucket.getAncestor()
			id = -1
			if ancestor is not None:
				id = ancestor.getID()

			bucketIDs = bucketAncestorMap.get(id, None)
			if bucketIDs is None:
				bucketIDs = set()
				bucketAncestorMap[id] = bucketIDs

			bucketIDs.add(bucket.getID())
			children = self.util.getAllBucketChildrenID(connection, bucket)
			for i in children:
				bucketIDs.add(i)

		#print(bucketAncestorMap)

		if deleteAccounts:
			accounts = bucketAncestorMap.get(-1, set())
			if len(accounts) > 0:
				accountStr = ", ".join(map(str, accounts))

				deleteBucketsSel = EnumBucketsTable.select(connection, SQL_WhereStatementBuilder("ID in (%s) OR Ancestor in (%s)" % (accountStr, accountStr)))
				deleteBucketsSel.deleteRows()

				deleteTransSel = EnumTransactionTable.select(connection, SQL_WhereStatementBuilder("SourceBucket in (%s)" % accountStr).OR("DestBucket in (%s)" % accountStr))
				deleteTransSel.deleteRows()

			return accounts
		else:
			bucketList: Set[int] = set()
			for j in bucketAncestorMap.items():
				if j[0] != -1:
					for a in j[1]:
						bucketList.add(a)

					#TODO: This could be more effiecent
					EnumTransactionTable.select(connection, SQL_WhereStatementBuilder("SourceBucket in (%s)" % ", ".join(map(str, j[1])))).setValues(EnumTransactionTable.SourceBucket, j[0])
					EnumTransactionTable.select(connection, SQL_WhereStatementBuilder("DestBucket in (%s)" % ", ".join(map(str, j[1])))).setValues(EnumTransactionTable.DestBucket, j[0])


			bucketStr = ", ".join(map(str, bucketList))
			deleteBucketsSelection = EnumBucketsTable.select(connection, SQL_WhereStatementBuilder("ID in (%s)" % bucketStr))
			deleteBucketsSelection.deleteRows()

			# This is an exception to the "Never delete transactions rule"
			# Transactions with a matching source and destination don't make any sense
			illegalTransSelection = EnumTransactionTable.select(connection, SQL_WhereStatementBuilder("SourceBucket == DestBucket"))
			illegalTransSelection.deleteRows()

			return bucketList