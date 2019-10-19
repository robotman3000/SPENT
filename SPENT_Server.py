import mimetypes, json, time, os
from wsgiref.simple_server import make_server
from SPENT.SPENT import *
from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument("--file", dest="dbpath",
                    default="SPENT.db")
parser.add_argument("--root", dest="serverRoot",
                    default="./web")
parser.add_argument("--debug",
                    action="store_true", dest="debugCore", default=False,
                    help="Enable debug logging")
parser.add_argument("--debug-API",
                    action="store_true", dest="debugAPI", default=False,
                    help="Enable API request logging")
parser.add_argument("--debug-Server",
                    action="store_true", dest="debugServer", default=False,
                    help="Enable server debugging features")
parser.add_argument("--server-mode",
					action="store_true", dest="serverMode", default=False,
					help="Run the server")

args = parser.parse_args()

#Begin Flag (Perf Mon Util)
def getTimeStr(timeMS):
	if timeMS > 1000:
		return "%s sec" % (timeMS / 1000)
	return "%s ms" % (timeMS)
	
def time_it(f, *args):
	start = time.time_ns()
	result = f(*args)
	return [result, (getTimeStr((time.time_ns() - start) / 1000000))]
#End Flag


class SPENTServer():
	def __init__(self, port=8080):
		self.unimp = {"successful": False, "message": "Unimplemented!"}
		self.accountMan = SpentDBManager(args.dbpath)
		self.spentUtil = SpentUtil(self.accountMan)
		self.spentUtil.registerUtilityColumns()
		
		self.showAPIData = args.debugAPI
		self.accountMan.printDebug = args.debugCore
		
		self.accountMan.connect()
		
		self.port = port
		
		self.handler = RequestHandler()
		self.handler.registerRequestHandler("POST", "/database/apiRequest", self.apiRequest)
	
		self.apiTree = {}
		self.apiTree["account"] = {"get": self.getAccount, "create": self.createAccount, "update": self.updateAccount, "delete": self.deleteAccount}
		self.apiTree["bucket"] = {"get": self.getBucket, "create": self.createBucket, "update": self.updateBucket, "delete": self.deleteBucket}
		self.apiTree["transaction"] = {"get": self.getTransaction, "create": self.createTransaction, "update": self.updateTransaction, "delete": self.deleteTransaction}
		self.apiTree["property"] = {"get": self.getProperty, "update": self.updateProperty}
		self.apiTree["enum"] = {"get": self.getEnum}

	def handleRequest(self, environ, start_response):
		print("\n--------------------------------------------------------------------------------\n")
		runTime = ""
		#resp = self.handler.get
		method = environ['REQUEST_METHOD']
		path = environ['PATH_INFO']
		queryStr = self.qsToDict(environ['QUERY_STRING'])
		
		response = None
		try:
			# Search for a mapping
			delegate = self.handler.getHandler(method, path)
			skipResponse = False
			if delegate is not None:
				print("Using registered handler for: %s - %s" % (method, path))
				if method == 'POST':
					try:
						request_body_size = int(environ['CONTENT_LENGTH'])
						request_body = environ['wsgi.input'].read(request_body_size)
						#response = time_it(delegate, queryStr, request_body_size, request_body)
						if self.showAPIData:
							print("POST Request Body: \n%s" % json.dumps(json.loads(request_body), indent=2))
					except (TypeError, ValueError):
						request_body = "0"
						
					resp = time_it(delegate, queryStr, request_body_size, request_body)
					response = resp[0]
					runTime = resp[1]
				else:
					resp = time_it(delegate, queryStr)
					response = resp[0]
					runTime = resp[1]
					#response = delegate(queryStr)
					
			else:
				resp = time_it(self.handler.fileHandler, queryStr, path)
				response = resp[0]
				runTime = resp[1]
				skipResponse = True
			
			start_response(response.getStatus(), response.getHeaders())
		except Exception as e:
			response_body = "An unhandled exception occured!!\n"
			response_body += str(e) + "\n"
			response_body += traceback.format_exc()
			print(response_body)
			status = '500 OK'
			headers = [('Content-type', 'text/text'),
				   ('Content-Length', str(len(response_body)))]
			response = ServerResponse(status, headers, response_body)
			start_response(response.getStatus(), response.getHeaders())
		
		if self.showAPIData:
			if not skipResponse:
				print("Server Response: %s" % response)
			else:
				print("Server Response: -File-")
				
		self.accountMan.save()
		
		# This should always print
		print("Request Delegate ran for: %s" % runTime)
		return [response.getBody()]
		
	def apiRequest(self, query, contentLen, content):
		request = json.loads(content)
		handlerFunc = self.invalidHandler
		
		typeDict = self.apiTree.get(request["type"], {})
		if typeDict is not None:
			print("API Request: %s %s" % (request["action"], request["type"]))
			handlerFunc = typeDict.get(request["action"], self.invalidHandler)
		
		requestedColumns = self.getRequestedColumns(request)
		result = time_it(handlerFunc, request, requestedColumns)
		
		if args.debugServer:
			print("API Request Handler Ran For: %s" % result[1])
		#result = handlerFunc(request, requestedColumns)
		if result[0] is None:
			result[0] = self.unimp
			
		responseBody = time_it(json.dumps, result[0])
		
		if args.debugServer:
			print("Serialization Took: %s" % responseBody[1])
		headers = [('Content-type', "text/json"),
				   ('Content-Length', str(len(responseBody[0])))]
		return ServerResponse("200 OK", headers, responseBody[0])
	
	def getRequestedColumns(self, request):
		data = request.get("columns", [])
		result = set(data)
		if len(result) > 0:
			result.add("ID")
		return result
	
	def invalidHandler(self, request, requestedColumns):
		return {"successful": False, "message": "Invalid action or type: (Action: %s, Type: %s)" % (request["action"], request["type"])}
	
	def start_server(self):
		"""Start the server."""
		self.httpd = make_server("", self.port, self.handleRequest)
		self.httpd.serve_forever()
	
	def qsToDict(self, queryString):
		result = {}
		spl = queryString.split("&")
		for i in spl:
			spl2 = i.split("=")
			if len(spl2) >= 2:
				result[str(spl2[0])] = str(spl2[1].replace("+", " "))
		
		if args.debugServer:
			print("QS To Dict: %s = %s" %(queryString, result))
		return result
	
	def formToDict(self, form):
		return self.qsToDict(form.decode("utf-8"))
		
	def SQLRowsToArray(self, rows, columns=[]):
		time = time_it(self.SQLRowsToArray_, rows, columns)
		if args.debugServer:
			print("Rows to Array ran for: " + time[1])
			
		return time[0]
	
	def SQLRowsToArray_(self, rows, columns=[]):
		records = []
		
		if args.debugServer:
			print("Rows: %s, Columns: %s" % (rows, columns))
		for i in rows:
			if i is not None:
				record = {}
				colList = columns
				if len(columns) < 1:
					colList = i.getColumnNames()

				for col in colList:
					record[col] = i.getValue(col)
				records.append(record)	
			else:
				print("Error: SQLRowsToArray: Processed a None row!")
		#print("Records: %s" % records)
		return records

	def dataToWhere(self, data):
		if data is not None and len(data) > 0:
			rowList = [int(row.get("ID", -1)) for row in data if row.get("ID", -1) is not None]
			return SQL_WhereStatementBuilder("ID in (%s)" % ", ".join(map(str, rowList)))
		return SQL_WhereStatementBuilder()
	
	def wrapData(self, data):
		return {"successful": True, "data": data}
	
	def saveDatabase(self, query):
		self.accountMan.save();
		responseBody = "Database Saved"
		headers = [('Content-type', "text/plain"),
				   ('Content-Length', str(len(responseBody)))]
		return ServerResponse("200 OK", headers, responseBody)
		
	def closeDatabase(self, query):
		self.accountMan.disconnect()
		self.running = False
		
	def getAccount(self, request, columns):
		data = request.get("data", None)
		rows = self.accountMan.getAccountsWhere(self.dataToWhere(data))
		result = self.SQLRowsToArray(rows, columns)
		return self.wrapData(result)

	def createAccount(self, request, columns):
		return self.createBucket(request, columns)
	
	def updateAccount(self, request, columns):
		return self.updateBucket(request, columns)
	
	def deleteAccount(self, request, columns):
		data = request.get("data", {})
		idList = [int(i.get("ID", -1)) for i in data]
		deleteList = self.accountMan.deleteAccountsWhere(SQL_WhereStatementBuilder("ID in (%s)" % ", ".join(map(str, idList))))
		return self.wrapData([{"ID": idVal} for idVal in deleteList])

	def getBucket(self, request, columns):
		data = request.get("data", [])
		rows = self.accountMan.getBucketsWhere(self.dataToWhere(data))
		result = self.SQLRowsToArray(rows, columns)
		return self.wrapData(result)

	def createBucket(self, request, columns):
		data = request.get("data", {})
		buckets = []
		for i in data:
			buckets.append(self.accountMan.createBucket(
				name=i.get("Name", 0),
				parent=i.get("Parent", -1)
			))
		return self.wrapData(self.SQLRowsToArray(buckets))
	
	def updateBucket(self, request, columns):
		data = request.get("data", {})
		results = []
		for i in data:
			bucket = self.accountMan.getBucket(int(i.get("ID", -1)))
			for j in i.items():
				bucket.updateValue(j[0], j[1])
			results.append(bucket)
			
		return self.wrapData(self.SQLRowsToArray(results))
	
	def deleteBucket(self, request, columns):
		data = request.get("data", {})
		idList = [int(i.get("ID", -1)) for i in data]
		deleteList = self.accountMan.deleteBucketsWhere(SQL_WhereStatementBuilder("ID in (%s)" % ", ".join(map(str, idList))))
		return self.wrapData([{"ID": idVal} for idVal in deleteList])
		
	def getTransaction(self, request, columns):
		data = request.get("data", {})
		accountID = request.get("rules", -1)
		account = None
		try:
			account = self.accountMan.getBucket(accountID)
		except:
			print("Failed to get account with id %s" % accountID)

		where = None
		if account is not None:
			transList = []
			if account.getParent() is None:
				transList = self.spentUtil.getAllBucketTransactionsID(account)
			else:
				transList = self.spentUtil.getBucketTransactionsID(account)

			where = SQL_WhereStatementBuilder("ID in (%s)" % ", ".join(map(str, transList)))

		transactions = self.accountMan.getTransactionsWhere(where)
		return self.wrapData(self.SQLRowsToArray(transactions, columns))
	
	def createTransaction(self, request, columns):
		data = request.get("data", {})
		results = []
		for i in data:
			results.append(self.accountMan.createTransaction(
				amount=i.get("Amount", 0),
				status=i.get("Status", 0),
				sourceBucket=self.accountMan.getBucket(int(i.get("SourceBucket", -1))),
				destBucket=self.accountMan.getBucket(int(i.get("DestBucket", -1))),
				transactionDate=i.get("TransDate", getCurrentDateStr()),
				postDate=i.get("PostDate", None),
				memo=i.get("Memo", ""),
				payee=i.get("Payee", "")))
		return self.wrapData(self.SQLRowsToArray(results))
	
	def updateTransaction(self, request, columns):
		data = request.get("data", {})
		results = []
		for i in data:
			bucket = self.accountMan.getTransaction(int(i.get("ID", -1)))
			for j in i.items():
				bucket.updateValue(j[0], j[1])
			results.append(bucket)
		return self.wrapData(self.SQLRowsToArray(results, columns))
	
	def deleteTransaction(self, request, columns):
		data = request.get("data", {})
		idList = [int(i.get("ID", -1)) for i in data]
		deleteList = self.accountMan.deleteTransactionsWhere(SQL_WhereStatementBuilder("ID in (%s)" % ", ".join(map(str, idList))))
		return self.wrapData([{"ID": idVal} for idVal in idList])
	
	def getProperty(self, request, columns):
		return self.unimp	
	
	def updateProperty(self, request, columns):
		return self.unimp	
	
	def getEnum(self, request, columns):
		return self.unimp	

class ServerResponse:
	def __init__(self, status, headers, body):
		self.status = status
		self.headers = headers
		self.body = body
		
	def getStatus(self):
		return self.status
	
	def getHeaders(self):
		return self.headers
	
	def getBody(self):
		if isinstance(self.body, str):
			return str.encode(self.body)
		return self.body
	
	def __str__(self):
		return "%s %s\n%s" % (self.getStatus(), self.getHeaders(), json.dumps(json.loads(self.getBody()), indent=2))
	
class RequestHandler:
	def __init__(self):
		self.handlers = {}
		
	def isText(self, typeGuess):
		#print(typeGuess)
		#if typeGuess[0].startswith('text'):# or typeGuess[0].startswith('application/javascript'):
		#	return True
		
		return False
	def fileHandler(self, query, path):
		if path == "/":
			path = "index.html"

		if path.startswith("/"):
			path = path[1:] # Remove the leading /

		print("Using file handler for: %s" % path)
		fullPath = os.path.join(args.serverRoot, path)
		if args.debugServer:
			print("Full file request path: %s" % fullPath)
		try:
				
			# we try to serve up a file with the requested name
			#TODO: Make a more robust file handler
			typeGuess = mimetypes.guess_type(fullPath)
			modeStr = "r%s" % ('t' if self.isText(typeGuess) else 'b')
			response_body = open(fullPath, mode=modeStr).read()
			status = '200 OK'
			headers = [('Content-type', typeGuess[0] if typeGuess[0] is not None else "application/octet-stream"),
				   ('Content-Length', str(len(response_body)))]

		except FileNotFoundError as e:
			response_body = "File not found"
			if args.debugServer:
				response_body +=  "\n" + args.serverRoot + path + "\n"
				response_body += "\n".join(os.listdir(args.serverRoot))
			status = '404 OK'
			headers = [('Content-type', 'text/plain'),
				   ('Content-Length', str(len(response_body)))]
		
		return ServerResponse(status, headers, response_body)
		
	def registerRequestHandler(self, method, path, delegate):
		print("Registering endpoint: %s - %s" % (method, path))
		self.handlers["%s;%s" % (method, path)] = delegate
	
	def getHandler(self, method, path):
		print("Searching for endpoint handler for: %s - %s" % (method, path))
		return self.handlers.get("%s;%s" % (method, path), None)

if args.serverMode:
	if sys.hexversion >= 0x30001f0:
		server = SPENTServer(8080)
		#server.open_browser()
		server.start_server()
	else:
		print("Sorry, your version of python is too old")
