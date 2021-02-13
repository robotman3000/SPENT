from typing import Callable, List
from curses import wrapper

import readline
from SPENT.SPENT_Schema_v1 import *
from SPENT.Old.SPENT import SpentUtil, SQL_WhereStatementBuilder, VirtualColumn
logman = log.getLogger("Main")

from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument("--file", dest="dbpath",
                    default="SPENT.db")
#parser.add_argument("--dump-db",
#                    action="store_true", dest="dbDumb", default=False,
#                    help="Dump's the database to the terminal")

args = parser.parse_args()

class REPL():
	def __init__(self, exitCallback, commands={}):
		self.running = False
		self.exitCallback = exitCallback
		self.commands = {
			'help': Command(self.listCommand),
			'exit': Command(self.exitCommand),
			**commands
		}

	def exitCommand(self, args, commandObj):
		if self.exitCallback is not None:
			self.exitCallback()
		self.running = False

	def listCommand(self, args, commandObj):
		for i in self.commands.items():
			print("%s; %s" % (i[0], i[1]))

	def main(self):
		self.running = True
		readline.set_completer(self.getCommandMatches)
		while self.running:
			rawStr = input("> ")
			rawStrParts = rawStr.split(";")
			if len(rawStrParts[0]) > 0:
				command = self.getCommand(rawStrParts[0])
				if command is not None:
					try:

						connection.beginTransaction()
						command.execute(rawStrParts[1:])

					except Exception as e:
						#print("Error: Runtime Exception: %s" % e)
						#traceback.print_exception(type(e), e, e.__traceback__)
						logman.exception(e)
						connection.abortTransaction()
					else:
						connection.endTransaction()

				# traceback.print_stack()
				else:
					logman.error("%s is not a valid command" % rawStrParts[0])

	def getCommand(self, command):
		return self.commands.get(command)

	def getCommandMatches(self, partial, state):
		if self.partial != partial:
			self.partial = partial
			self.completes = self.getMatches()

		if state > len(self.completes):
			return -1
		else:
			return self.completes[state]

	def getMatches(self, string):
		result = []
		for i in self.commands.items():
			if i[0].startswith(string):
				result.append(i[0])
				print("Match: %s" % i[0])

class Command():
	def __init__(self, callback: Callable, usage: str = ""):
		self.callback = callback
		self.usage = usage
		self.argCount = len(usage.split(";")) if len(self.usage) > 0 else 0

	def execute(self, args: List[str]) -> None:
		if (len(args) >= self.argCount):
			result = connection.execute("PRAGMA foreign_keys")
			print("Pragma: %s" % result[0][0])
			self.callback(args, self)
		else:
			logman.error("Invalid Argument Count: Expected %d, Got %d" % (self.argCount, len(args)))
			logman.error("Args: " + str(self))

	def __str__(self):
		return self.usage if self.usage != None else ""

def shellPrint(string):
	print("Shell: %s" % str(string))

database = sqlib.Database(SPENT_DB_V1, args.dbpath)
# TODO: Stop using global connection once the transaction commit system is implemented
connection = database.getConnection("Shell")
connection.connect()

def rawSQL(command: List[str], commandObject) -> None:
	result = connection.execute(command[0])
	if result is not None:
		for row in result:
			shellPrint(tuple(row))
	else:
		shellPrint("Empty Result")

def exitCallback():
	logman.info("Exiting...")
	connection.disconnect(True)

def dumpDB(args, commandObject):
	pass

def setLogLevel(command: List[str], commandObject) -> None:
	try:
		log.setLevel(command[0].strip())
	except Exception as e:
		logman.exception(e)
		shellPrint("Valid Levels: %s" % "CRITICAL, ERROR, WARNING, INFO, DEBUG, NOTSET")
	logman.info("Log Message Level: %s" % logman.getEffectiveLevel())

commands = {
	'raw' : Command(rawSQL),
	'setLevel' : Command(setLogLevel, "Level Name"),
}
#------------------------------------------------------------------------------

def getProperty():
	pass

def setProperty():
	pass

def listProperties():
	pass

#------------------------------------------------------------------------------

def showAccountTree(command: List[str], commandObject) -> None:
	shellPrint("ID, Name, Available, Posted")

	for a in EnumBucketsTable.select(connection, SQL_WhereStatementBuilder("%s == -1" % EnumBucketsTable.Ancestor.name)):
		printTree(a)

def printTree(bucket: Bucket, depth: int = 0) -> None:
	shellPrint("%s %d - %s ($%s, $%s)" % (" ".join([" | " for i in range(0, depth)]), bucket.getID(), bucket.getName(), SpentUtil.getAvailableBalance(connection, bucket), SpentUtil.getPostedBalance(connection, bucket)))
	for child in SpentUtil.getBucketChildren(connection, bucket):
		printTree(child, depth+1)

def showBucket(command: List[str], commandData) -> None:
	bucket = EnumBucketsTable.getRow(connection, int(command[0]))
	if bucket is not None:
		shellPrint("===== %s =====" % bucket.getName())
		shellPrint("Avail Balance: %s" % SpentUtil.getAvailableBalance(connection, bucket))
		shellPrint("Posted Balance: %s" % SpentUtil.getPostedBalance(connection, bucket))
		listBucketTransactions(bucket)
	else:
		logman.warning("No bucket with ID %s exists" % command[0])

def listBucketTransactions(bucket) -> None:
	if bucket is not None:
		shellPrint("Transactions:")
		transList = SpentUtil.getAllBucketTransactions(connection, bucket)
		for trans in transList:
			e = EnumTransactionTable
			propList = [e.id, e.Status, e.TransDate, e.PostDate, e.Amount, e.SourceBucket, e.DestBucket]#, e.isTransfer]
			#TODO: Reimplement remapping column values
			#res = ", ".join(map(str, [("%s: %s" % (i, trans.getValueRemapped(i))) for i in propList]))
			res = ", ".join(map(str, [("%s: %s" % (i.name, trans.getValue(i))) for i in propList]))
			shellPrint(res)

#------------------------------------------------------------------------------

def exportMMEX(command, commandObject):
	import csv
	# This function exports the database as a csv file in a format compatible with Money Manager EX

	# We need to create a seperate csv file for each account
	#for account:

		# Bucket
		# ID = None
		# Name = Category Name or Sub Category Name
		# Parent = None

		# Transaction
		# ID = None
		# Status = Unint, Submit, Post-Pending - Insert note and status none, Complete - Status none, Reconciled - Match, Void - Match
		# Date and Post-Date = Prefer Post-Date
		# Amount = Deposit and Withdrawal
		# Source and Dest Bucket = Category or Subcategory
		# Memo = Note
		# Payee = Payee (Except for transfers - > + From/To Name with > Greater towards FROM)
	buckets = EnumBucketsTable.select(connection, SQL_WhereStatementBuilder())

	# First map all bucket id's to categories (Merge the category's of all the accounts into one list)
	categoriesMap = {}
	for bucket in EnumBucketsTable.select(connection, SQL_WhereStatementBuilder("Ancestor != -1")).getRows().values():
		print("Mapping %s to %s" % (bucket.getID(), bucket.getName()))
		categoriesMap[bucket.getID()] = bucket.getName()


	for account in EnumBucketsTable.select(connection, SQL_WhereStatementBuilder("Ancestor = -1")).getRows().values():
		with open('mmex-%s.csv' % account.getName(), 'w', newline='') as file:
			writer = csv.writer(file)
			writer.writerow(["Date", "Payee", "Category", "SubCategory", "Number", "Notes", "Deposit", "Withdrawal"])

			index = 0
			print("Processing Account %s" % account.getName())

			chil = SpentUtil.getAllBucketChildrenID(connection, account)
			chil.append(account.getID())
			bucketChildren = ", ".join(map(str, chil))
			for transaction in EnumTransactionTable.select(connection, SQL_WhereStatementBuilder("SourceBucket in (%s)" % bucketChildren).OR("DestBucket in (%s)" % bucketChildren)):
				#print("Checking %s %s" % (transaction.getType(), transaction.getID()))
				# Ignore all "transfer" transactions between buckets with the same ancestor
				sourceAncestor = buckets.getRow(transaction.getSourceBucketID()).getAncestorID()
				if sourceAncestor is -1 or sourceAncestor is None:
					sourceAncestor = transaction.getSourceBucketID()

				destAncestor = buckets.getRow(transaction.getDestBucketID()).getAncestorID()
				if destAncestor is -1 or destAncestor is None:
					destAncestor = transaction.getDestBucketID()

				print("%s,%s and %s,%s and %s" % (sourceAncestor, transaction.getSourceBucketID(), destAncestor, transaction.getDestBucketID(), transaction.getType()))
				if sourceAncestor == destAncestor:
					print("Ignoring transfer %s" % transaction.getID())
				else:
					transDirection = None
					if transaction.getType() == 0:
						transDirection = (destAncestor == account.getID())
					elif transaction.getType() == 1:
						transDirection = True
					else:
						transDirection = False

					# We assume that exactly one of the two will be -1 and the other != -1
					primaryBucketID = transaction.getDestBucketID() if transDirection else transaction.getSourceBucketID()

					if transaction.getType() == 0:
						# We have a transfer
						print("Parsing transfer %s" % transaction.getID())
						category = "Transfer"
					else:
						print("Parsing %s %s" % (transaction.getType(), transaction.getID()))

						# If there is no mapping that means that the pri ID is that of an account, for which there is no category
						candidateName = categoriesMap.get(primaryBucketID)
						category = candidateName if candidateName is not None else ""

					date = transaction.getPostDate() if transaction.getPostDate() is not None and transaction.getPostDate() != "" else transaction.getTransactionDate()
					deposit = transaction.getAmount() if transDirection else ""
					withdrawal = transaction.getAmount() if not transDirection else ""
					primaryBucketName = buckets.getRow(primaryBucketID).getName()
					payee = transaction.getPayee() if transaction.getType() != 0 else "< %s" % primaryBucketName if transDirection else "> %s" % primaryBucketName

					if transaction.getStatus() != TransactionStatusEnum.Complete.value and transaction.getStatus() != TransactionStatusEnum.Reconciled.value:
						statusStr = "[%s] " % transaction.getStatus()
					else:
						statusStr = ""

					notes = "%s%s" % (statusStr, transaction.getMemo())
					writer.writerow([date, payee, category, "", "", notes, deposit, withdrawal])
					#print("CSV: %s, %s, %s, %s,	%s, %s, %s, %s, %s" % (index, date, payee, category, "", "", notes, deposit, withdrawal))
				print("---------------------")
				# "#[Index], Date[Trans Date || Post Date], Payee[%s unless Type is Transfer then (direction ? ">" + Destination Name : "<" + Source Name) + ], Category[Bucket Name], Number, Deposit[AMOUNT if SourceBucket is -1 or None], Withdrawal[AMOUNT if DestBucket is -1 or None]"
				#  Category[Bucket Name], Number"
				# Choose which date to use
				# Decide whether the AMOUNT is Deposit or Withdrawal

				index += 1
			# MMEX doesn't share our idea of categories being owned by an account
			# so when we convert we will prefix the category name with the account id to preserve that information
			# and then we


#------------------------------------------------------------------------------

def createFunction(table, connection, args, command):
	data = {}
	for index in range(len(command.args)):
		column = command.args[index][0]
		data[column] = args[index]

	print(data)
	table.createRow(connection, data)

def updateFunction(table, connection, args, obj):
	kvp = args[1].split(":")
	rowID = args[0];
	data = table.getRow(connection, rowID)
	data.setValue(table[kvp[0].strip()], kvp[1])

def deleteFunction(table, connection, args, obj):
	rowID = args[0]
	table.deleteRow(connection, rowID)

def listFunction(table, connection, args, obj):
	shellPrint("Listing %s" % table.getTableName(table))
	rowSelection = table.select(connection, None)
	columns = table.getColumns(table)
	for row in rowSelection:
		printRow(row, columns)

def showFunction(table, connection, args, obj):
	id = args[0]
	row = table.getRow(connection, id)
	printRow(row, row.getColumns())

def printRow(row, columns):
	data = {}
	for col in columns:
		data[col.name] = row.getValue(col)

	shellPrint(data)

dataTypes = {"Transaction": EnumTransactionTable, "Bucket": EnumBucketsTable, "Tag": EnumTagsTable}
actions = {"Create": createFunction, "Update": updateFunction, "Delete": deleteFunction, "List": listFunction,  "Show": showFunction}

def tableActionHandler(command: List[str], commandObject):
	table = commandObject.table
	function = commandObject.function

	#TODO: Create new connections for each command
	function(table, connection, command, commandObject)

def remap(input):
	return "%s [%s]" % (input[0].name, input[1].name)

connect = database.getConnection("InitTables")
connect.connect(False)
connect.beginTransaction()
#database.initTable(EnumTransactionGroupsTable, connect)
#database.initTable(EnumTransactionTagsTable, connect)

for dtype in dataTypes.items():
	table = dtype[1]
	typeName = dtype[0]

	# Init the table in the DB
	#database.initTable(table, connect)

	for action in actions.items():
		actionName = action[0]
		actionFunction = action[1]

		commandName = "%s%s" % (actionName, typeName)
		# TODO: Construct the list of arguments based on the required fields in the table

		args = []
		if actionName == "Create":
			for column in table.getColumns(table):
				if not column.value.willAutoIncrement() and not type(column.value) is VirtualColumn:
					args.append( (column, column.value.getType()) )

		if actionName == "Update":
			args = ["ID", "Key:Value"]

		if actionName == "Delete" or actionName == "Show":
			args = ["ID"]

		# if actionName == "List":
		# No args

		if actionName == "Create":
			argsStr = "; ".join(map(remap, args))
		else:
			argsStr = "; ".join(args)

		commands[commandName] = Command(tableActionHandler, argsStr)
		commands[commandName].table = table
		commands[commandName].function = actionFunction
		commands[commandName].args = args

connect.endTransaction()

#commands['GetProperty']
#commands['SetProperty']
#commands['ListProperties']

commands['ls'] = Command(showAccountTree)
commands['info'] = Command(showBucket, "ID")
commands['dump'] = Command(dumpDB)
commands['exportMMEX'] = Command(exportMMEX)

#setLogLevel(["INFO"], None)
repl = REPL(exitCallback, commands)
repl.main()