from SPENT import *
from SPENT_Util import *
import readline
import traceback

class REPL():
	def __init__(self, exitCallback, commands={}):
		self.running = False
		self.exitCallback = exitCallback
		self.commands = {
			'help' : Command(self.listCommand),
			'exit' : Command(self.exitCommand),
			**commands
		}
	
	def exitCommand(self, args):
		if self.exitCallback is not None:
			self.exitCallback()
		self.running = False
	
	def listCommand(self, args):
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
						command.execute(rawStrParts[1:])
					except Exception as e:
						print("Error: Runtime Exception: %s" % e)
						traceback.print_exception(type(e), e, e.__traceback__)
						
						#traceback.print_stack()
				else:
					print("Error: %s is not a valid command" % rawStrParts[0])
				
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
		if(len(args) >= self.argCount):
			self.callback(args)
		else:
			print("Error: Invalid Argument Count: Expected %d, Got %d" % (self.argCount, len(args)))
			print("Args: " + str(self))
		
	def __str__(self):
		return self.usage if self.usage != None else ""
	
class UpdateCommand(Command):
	def __init__(self, getByIDFunc):
		super().__init__(self.updateCallback, "ID; Key:Value")
		self.getByIDFunc = getByIDFunc
		
	def updateCallback(self, command):
		kvp = command[1].split(":")
		data = self.getByIDFunc(int(command[0]))
		data.updateValue(kvp[0], kvp[1])
	
class ListCommand(Command):
	def __init__(self, listSourceFunc):
		super().__init__(self.listCallback)
		self.listSourceFunc = listSourceFunc
		
	def listCallback(self, command):
		lis = self.listSourceFunc()
		self.printRows(lis)	

	def printRows(self, rows):
		for a in rows:
			print(a)

accountMan = SpentDBManager()
spentUtil = SpentUtil(accountMan)
spentUtil.registerUtilityColumns()
accountMan.printDebug = True
accountMan.connect()

def printTree(bucket: Bucket, depth: int = 0) -> None:
	print("%s %d - %s ($%s, $%s)" % (" ".join([" | " for i in range(0, depth)]), bucket.getID(), bucket.getName(), spentUtil.getAvailableBalance(bucket), spentUtil.getPostedBalance(bucket)))
	for child in spentUtil.getBucketChildren(bucket):
		printTree(child, depth+1)
						   
def callback():
	print("Exiting...")
	saveDB(None)
	accountMan.disconnect()

def rawSQL(command: List[str]) -> None:
	accountMan._rawSQL_(command[0])
		
def addAccount(command: List[str]) -> None:
	accountMan.createAccount(command[0])

def addBucket(command: List[str]) -> None:
	accountMan.createBucket(command[0], int(command[1]))

def deleteBucket(command: List[str]) -> None:
	bucket = accountMan.getBucket(int(command[0]))
	if bucket is not None:
		accountMan.deleteBucket(bucket)
	else:
		print("No bucket with ID %s exists" % command[0])

def addTransaction(command: List[str]) -> None:
	accountMan.createTransaction(amount=float(command[0]),
								 sourceBucket=accountMan.getBucket(int(command[1])),
								 destBucket=accountMan.getBucket(int(command[2])),
								 transactionDate=command[3],
								 memo=command[4])
	
def deleteTransaction(command: List[str]) -> None:
	accountMan.deleteTransaction(accountMan.getTransaction(int(command[0])))

def listBucketTransactions(command: List[str]) -> None:
	bucket = accountMan.getBucket(int(command[0]))
	if bucket is not None:
		print("Transactions:")
		transList = spentUtil.getAllBucketTransactions(bucket)
		for trans in transList:
			propList = ["ID", "Status", "TransDate", "PostDate", "Amount", "SourceBucket", "DestBucket", "IsTransfer"]
			res = ", ".join(map(str, [("%s: %s" % (i, trans.getValueRemapped(i))) for i in propList]))
			print(res)
	else:
		print("No bucket with ID %s exists" % command[0])

def showAccountTree(command: List[str]) -> None:
	print("ID, Name, Available, Posted")
	for a in accountMan.getAccountsWhere():
		printTree(a)

def showBucket(command: List[str]) -> None:
	bucket = accountMan.getBucket(int(command[0]))
	if bucket is not None:
		print("===== %s =====" % bucket.getName())
		print("Avail Balance: %s" % spentUtil.getAvailableBalance(bucket))
		print("Posted Balance: %s" % spentUtil.getPostedBalance(bucket))
		listBucketTransactions(command)
	else:
		print("No bucket with ID %s exists" % command[0])
	
def toggleDebug(command: List[str]) -> None:
	accountMan.printDebug = not accountMan.printDebug
	print("Debug Messages: %s" % accountMan.printDebug)
	
def showTransaction(command: List[str]) -> None:
	trans = accountMan.getTransaction(int(command[0]))
	propList = ["Status", "TransDate", "PostDate", "Amount", "SourceBucket", "DestBucket"]
	
	for i in propList:
		print("%s: %s" % (i, trans.getValue(i)))
	
def saveDB(command: Optional[List[str]]) -> None:
	print("Saving Database...")
	accountMan.save()
	print("Changes Saved.")

repl = REPL(callback, {
	'raw' : Command(rawSQL),
	'save' : Command(saveDB),

	'UpdateBucket' : UpdateCommand(accountMan.getBucket), #ScrollMenu Item (i) Button
	'UpdateTransaction' : UpdateCommand(accountMan.getTransaction),  #ScrollMenu Item (i) Button

	'CreateBucket' : Command(addBucket, "Name; Parent ID"), #Header Plus Button
	'CreateTransaction' : Command(addTransaction, "Amount; Source Bucket ID, Dest Bucket ID, YYYY-MM-DD; Memo"), #Header Plus Button
	
	'DeleteBucket' : Command(deleteBucket, "ID"), #Swipe To Delete
	'DeleteTransation' : Command(deleteTransaction, "ID"), #Swipe To Delete

	'ListBuckets' : ListCommand(accountMan.getBucketsWhere), # ScrollMenu
	'ListAccounts' : ListCommand(accountMan.getAccountsWhere), # ScrollMenu
	'ListTransactions' : ListCommand(accountMan.getTransactionsWhere), # ScrollMenu

	'ShowBucket' : Command(showBucket, "ID"), #ScrollMenu Item Tapped
	'ShowTransaction' : Command(showTransaction, "ID"), #ScrollMenu Item Tapped
	
	'ls' : Command(showAccountTree),
	'ToggleDebug' : Command(toggleDebug),
})
repl.main()
