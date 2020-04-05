from typing import Callable, List

import readline
from SPENT.SPENT_Schema import *
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

database = sqlib.Database(args.dbpath)

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
			propList = [e.ID, e.Status, e.TransDate, e.PostDate, e.Amount, e.SourceBucket, e.DestBucket]#, e.isTransfer]
			#TODO: Reimplement remapping column values
			#res = ", ".join(map(str, [("%s: %s" % (i, trans.getValueRemapped(i))) for i in propList]))
			res = ", ".join(map(str, [("%s: %s" % (i.name, trans.getValue(i))) for i in propList]))
			shellPrint(res)

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
database.initTable(EnumTransactionGroupsTable, connect)
database.initTable(EnumTransactionTagsTable, connect)

for dtype in dataTypes.items():
	table = dtype[1]
	typeName = dtype[0]

	# Init the table in the DB
	database.initTable(table, connect)

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


#setLogLevel(["INFO"], None)
repl = REPL(exitCallback, commands)
repl.main()
