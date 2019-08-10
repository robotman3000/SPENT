import threading
import webbrowser
from wsgiref.simple_server import make_server
import mimetypes
import traceback
from SPENT import *
import json
import time

FILE = 'index.html'

def getTimeStr(timeMS):
	if timeMS > 1000:
		return "%s sec" % (timeMS / 1000)
	return "%s ms" % (timeMS)
	
def time_it(f, *args):
	start = time.time_ns()
	result = f(*args)
	return [result, (getTimeStr((time.time_ns() - start) / 1000000))]

class SPENTServer():
	def __init__(self, port=8080):
		self.unimp = {"successful": False, "message": "Unimplemented!"}
		self.accountMan = AccountManager()
		self.showAPIData = False
		self.accountMan.printDebug = False
		
		properties = {
			"Buckets":
				{
					"ID": {"title": "ID", "type": "number", "visible": False},
				 	"Name": {"title": "Name", "type": "string", "required": True},
				 	"Parent": {"title": "Parent", "type": "number", "required": True},
				 	"Category": {"title": "Category", "type": "number"},
				},
			"Transactions": 
				{
					"ID": {"title": "ID", "type": "number", "visible": False, "filterable":False},
					"Status": {"title": "Status", "type": "enum", "breakpoints":"xs sm md"},
					"TransDate": {"title": "Date", "type": "date", "breakpoints":"xs","formatString":"YYYY-MM-DD", "required": True},
					"PostDate": {"title": "Posted", "type": "date", "breakpoints":"xs sm md", "formatString":"YYYY-MM-DD"},
					"Amount": {"title": "Amount", "type": "number", "breakpoints":"", "required": True},
					"SourceBucket": {"title": "Source", "type": "mapping", "breakpoints":"xs sm md", "required": True},
					"DestBucket": {"title": "Destination", "type": "mapping", "breakpoints":"xs sm md", "required": True},
					"Memo": {"title": "Memo", "type": "string", "breakpoints":""},
					"Payee": {"title": "Payee", "type": "string", "breakpoints":"xs sm"},
				},
		}

		for table in properties.items():
			tableName = table[0]
			for column in table[1].items():
				columnName = column[0]
				for props in column[1].items():
					propertyName = props[0]
					self.accountMan.registerTableSchemaColumnProperty(tableName, columnName, propertyName, props[1])
					
		def getAllBucketChildren(source, tableName, columnName):
			return source.getAllChildrenID()
		
		self.accountMan.registerVirtualColumn("Buckets", "AllChildren", getAllBucketChildren)
		
		self.accountMan.connect()
		
		self.port = port
		
		self.handler = RequestHandler()
		self.handler.registerRequestHandler("GET", "/database/schema/columns", self.getTableSchema)
		self.handler.registerRequestHandler("POST", "/database/apiRequest", self.apiRequest)
	
		self.apiTree = {}
		self.apiTree["account"] = {"get": self.getAccount, "create": self.createAccount, "update": self.updateAccount, "delete": self.deleteAccount}
		self.apiTree["bucket"] = {"get": self.getBucket, "create": self.createBucket, "update": self.updateBucket, "delete": self.deleteBucket}
		self.apiTree["transaction"] = {"get": self.getTransaction, "create": self.createTransaction, "update": self.updateTransaction, "delete": self.deleteTransaction}
		self.apiTree["property"] = {"get": self.getProperty, "update": self.updateProperty}
		self.apiTree["enum"] = {"get": self.getEnum}

	def handleRequest(self, environ, start_response):
		print("\n--------------------------------------------------------------------------------\n")
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
						
					response = delegate(queryStr, request_body_size, request_body)
				else:
					#response = time_it(delegate, queryStr)
					response = delegate(queryStr)
			else:
				response = self.handler.fileHandler(queryStr, path)
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
		print("API Request Handler Ran For: %s" % result[1])
		#result = handlerFunc(request, requestedColumns)
		if result[0] is None:
			result[0] = self.unimp
			
		responseBody = time_it(json.dumps, result[0])
		print("Serialization Took: %s" % responseBody[1])
		headers = [('Content-type', "text/json"),
				   ('Content-Length', str(len(responseBody[0])))]
		return ServerResponse("200 OK", headers, responseBody[0])
	
	def getRequestedColumns(self, request):
		#TODO: Make this look at more than one row
		data = request.get("data", None)
		result = set()
		if data is not None:
			for i in data:
				for j in i.items():
					# We make a special allowance for the ID column here becuase
					# it is a special colum. Without it the response is difficult/imposible to parse
					# correctly in most cases
					if j[1] is None or j[0] == "ID":
						#print("Requested Column: %s" % j[0])
						result.add(j[0])
		return result
	
	def invalidHandler(self, request, requestedColumns):
		return {"successful": False, "message": "Invalid action or type: (Action: %s, Type: %s)" % (request["action"], request["type"])}
		
	def open_browser(self):
		"""Start a browser after waiting for half a second."""
		def _open_browser():
			webbrowser.open('http://localhost:%s/%s' % (self.port, FILE))
		thread = threading.Timer(0.5, _open_browser)
		thread.start()

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
		
		print("QS To Dict: %s = %s" %(queryString, result))
		return result
	
	def formToDict(self, form):
		return self.qsToDict(form.decode("utf-8"))
		
	def SQLRowsToArray(self, rows, columns):
		time = time_it(self.SQLRowsToArray_, rows, columns)
		print("Rows to Array ran for: " + time[1])
		return time[0]
	
	def SQLRowsToArray_(self, rows, columns=[]):
		records = []
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
		
	def SQLRowsToJSON(self, rows, columns=[]):
		return json.dumps(self.SQLRowsToArray(rows, columns))
	
	def SQLRowsToRecords(self, rows, columns=[]):
		records = []
		for i in rows:
			record = {}
			colList = columns
			if len(columns) < 1:
				colList = i.getColumnNames()
							
			for col in colList:
				record[col] = i.getValue(col)
			records.append(record)
			
		result = {"Result": "OK", "Records": records}
		result["TotalRecordCount"] = len(records)
		return json.dumps(result)
	
	def SQLRowToRecord(self, row, columns=[]):
		record = {}
		colList = columns
		if len(columns) < 1:
			colList = row.getColumnNames()

		for col in colList:
			record[col] = row.getValue(col)
			
		result = {"Result": "OK", "Record": record}
		return json.dumps(result)
	
	def SQLRowsToOptions(self, rows, displayKey, valueKey):
		statusList = [{"DisplayText": str(rows[index].getValue(displayKey)), "Value": str(rows[index].getValue(valueKey))} for index in range(len(rows))]
		return json.dumps({"Result" : "OK", "Options": statusList})
	
	def SQLRowsToNodes(self, rows):
		result = []
		for i in rows:
			parentID = -1
			if i.getParent() is not None:
				parentID = i.getParent().getID()
			node = {"id": i.getID(), "parent": ("#" if parentID == -1 else parentID), "text": i.getName(), "data": {"balance": i.getBalance()}}
			children = i.getChildren()
			if len(children) > 0:
				node["children"] =  True
			result.append(node)
		return json.dumps(result)
		
	def saveDatabase(self, query):
		self.accountMan.save();
		responseBody = "Database Saved"
		headers = [('Content-type', "text/plain"),
				   ('Content-Length', str(len(responseBody)))]
		return ServerResponse("200 OK", headers, responseBody)
		
	def closeDatabase(self, query):
		self.accountMan.disconnect()
		self.running = False

		
	def getTableSchema(self, query):
		#TODO: remove this
		tableNames = {"transactionTable": "Transactions", "bucketTable": "Buckets", "accountTable": "Buckets"}
		tableName = tableNames.get(query["tableName"], None)
		responseBody = json.dumps(self.accountMan.getTableSchema(tableName))
		headers = [('Content-type', "text/json"),
				   ('Content-Length', str(len(responseBody)))]
		return ServerResponse("200 OK", headers, responseBody)
		
	def getAccount(self, request, columns):
		rows = []
		data = request.get("data", None)
		if data is not None and len(data) > 0:
			for row in data:
				rows.append(self.accountMan.getBucket(row.get("ID", -1)))
		else:
			rows = self.accountMan.getAccountList()
			
		result = self.SQLRowsToArray(rows, columns)
		return {"successful": True, "data": result}

	def createAccount(self, request, columns):
		return self.createBucket(request, columns)
	
	def updateAccount(self, request, columns):
		return self.updateBucket(request, columns)
	
	def deleteAccount(self, request, columns):
		return self.deleteBucket(request, columns)
		
	def getBucket(self, request, columns):
		rows = []
		data = request.get("data", None)
		if data is not None and len(data) > 0:
			for row in data:
				rows.append(self.accountMan.getBucket(row.get("ID", -1)))
		else:
			rows = self.accountMan.getBucketList()
			
		result = self.SQLRowsToArray(rows, columns)
		return {"successful": True, "data": result}

	def createBucket(self, request, columns):
		data = request.get("data", {})
		results = []
		for i in data:
			result = self.accountMan.createBucket(
				name=i.get("Name", 0),
				parent=i.get("Parent", -1)
			)

			bucket = self.accountMan.getBucket(result)
			results.append(bucket)
		result = self.SQLRowsToArray([bucket])
		return {"successful": True, "data": result}
	
	def updateBucket(self, request, columns):
		data = request.get("data", {})
		results = []
		for i in data:
			bucket = self.accountMan.getBucket(int(i.get("ID", -1)))
			
			for j in i.items():
				bucket.updateValue(j[0], j[1])
			
			results.append(bucket)
		result = self.SQLRowsToArray([bucket])
		return {"successful": True, "data": result}
	
	def deleteBucket(self, request, columns):
		data = request.get("data", {})
		results = []
		for i in data:
			bucket = self.accountMan.getBucket(int(i.get("ID", -1)))
			
			# Do this before the delete so that we can use the bucket object
			results.append({"ID": bucket.getID()})
			
			self.accountMan.deleteBucket(bucket)
			
		return {"successful": True, "data": results}
		
	def getTransaction(self, request, columns):
		rows = []
		data = request.get("data", None)
		if data is not None:
			for row in data:
				rows.append(self.accountMan.getTransaction(row.get("ID", -1)))
		else:
			self.accountMan.getTransactionList()
			
		result = self.SQLRowsToArray(rows, columns)
		return {"successful": True, "data": result}

	def createTransaction(self, request, columns):
		data = request.get("data", {})
		results = []
		for i in data:
			result = self.accountMan.createTransaction(
				amount=i.get("Amount", 0),
				status=i.get("Status", 0),
				sourceBucket=self.accountMan.getBucket(int(i.get("SourceBucket", -1))),
				destBucket=self.accountMan.getBucket(int(i.get("DestBucket", -1))),
				transactionDate=i.get("TransDate", getCurrentDateStr()),
				postDate=i.get("PostDate", None),
				memo=i.get("Memo", ""),
				payee=i.get("Payee", ""))

			transaction = self.accountMan.getTransaction(result)
			results.append(transaction)
		result = self.SQLRowsToArray([transaction])
		return {"successful": True, "data": result}
	
	def updateTransaction(self, request, columns):
		data = request.get("data", {})
		results = []
		for i in data:
			bucket = self.accountMan.getTransaction(int(i.get("ID", -1)))
			
			for j in i.items():
				bucket.updateValue(j[0], j[1])
			
			results.append(bucket)
		result = self.SQLRowsToArray([bucket])
		return {"successful": True, "data": result}
	
	def deleteTransaction(self, request, columns):
		data = request.get("data", {})
		results = []
		for i in data:
			bucket = self.accountMan.getTransaction(int(i.get("ID", -1)))
			
			# Do this before the delete so that we can use the transaction object
			results.append({"ID": bucket.getID()})
			
			self.accountMan.deleteTransaction(bucket)
			
		return {"successful": True, "data": results}
	
	def getProperty(self, request, columns):
		return self.unimp	
	
	def updateProperty(self, request, columns):
		return self.unimp	
	
	def getEnum(self, request, columns):
		return self.unimp	
	
	
	
		
	def DEPgetStatusList(self, query, contentLen, content):
		rows = self.accountMan._tableSelectDelete_(False, "StatusMap")
		responseBody = self.SQLRowsToOptions(rows, "Name", "ID")
		headers = [('Content-type', "text/json"),
				   ('Content-Length', str(len(responseBody)))]
		return ServerResponse("200 OK", headers, responseBody)

	def DEPgetTransactionTypeList(self, query, contentLen, content):
		rows = self.accountMan._tableSelectDelete_(False, "TypeMap")
		responseBody = self.SQLRowsToOptions(rows, "Name", "ID")
		headers = [('Content-type', "text/json"),
				   ('Content-Length', str(len(responseBody)))]
		return ServerResponse("200 OK", headers, responseBody)
	
	def DEPgetAccountTransactions(self, query):
		transactions = []
		bucket = self.accountMan.getBucket(int(query["account"]))
		if bucket is not None:
			rows = bucket.getAllTransactions()
			responseBody = self.SQLRowsToJSON(rows)
			status = "200 OK"
		else:
			responseBody = "No account with id %s exists" % query["account"]
			status = "500 OK"
			print("No account with id %s exists" % query["account"])
			#responseBody = json.dumps({ "Result":"ERROR", "Message": "No account with id %s exists" % query["account"]})
			
		#	transactions.append({"id": i.getID(), "status": i.getStatus(), "transDate": i.getTransactionDate(), "postDate": i.getPostDate(), "amount": i.getAmount(), "bucket": i.getBucket().getID(), "userNotes": i.getUserNotes()})
		
		headers = [('Content-type', "text/json"),
				   ('Content-Length', str(len(responseBody)))]
		return ServerResponse(status, headers, responseBody)
	
	def DEPupdateTransaction(self, query, contentLen, content):
		formData = self.formToDict(content)
		tID = formData["ID"]
		trans = self.accountMan.getTransaction(tID)
		for i in formData.items():
			trans.updateValue(i[0], i[1])
		responseBody = self.SQLRowToRecord(trans)
		headers = [('Content-type', "text/json"),
		   ('Content-Length', str(len(responseBody)))]
		return ServerResponse("200 OK", headers, responseBody)
	
	def DEPdeleteTransaction(self, query, contentLen, content):
		formData = self.formToDict(content)
		tID = formData["ID"]
		trans = self.accountMan.getTransaction(tID)
		self.accountMan.deleteTransaction(trans)
		responseBody = json.dumps({"Result": "OK"})
		headers = [('Content-type', "text/json"),
		   ('Content-Length', str(len(responseBody)))]
		return ServerResponse("200 OK", headers, responseBody)
				
	def DEPcreateTransaction(self, query, contentLen, content):
		formData = self.formToDict(content)
		amount = formData.get("Amount")
		bucket = self.accountMan.getBucket(formData.get("Bucket", -1))
		notes = formData.get("UserNotes", "")
		date = formData.get("TransDate", -1)
		
		newID = self.accountMan.createTransaction(amount, bucket, transactionDate=date, description=notes)
		
		newTrans = self.accountMan.getTransaction(newID)
		
		responseBody = self.SQLRowToRecord(newTrans)
		headers = [('Content-type', "text/json"),
		   ('Content-Length', str(len(responseBody)))]
		return ServerResponse("200 OK", headers, responseBody)
	
	def DEPgetAccounts(self, query):
		status = "200 OK"
		contentType = "text/plain"
		responseBody=""
		form = query["format"]
				
		if form is not None:
			if form == "html-select":
				result = "<select id=\"accountSelect\">\n"
				for i in self.accountMan.getAccountList():
					result += "\t<option value=\"%s\">%s</option>\n" % (i.getID(), i.getName())
				result += "</select>"
				responseBody = result
				contentType = "text/html"
			elif form == "recordList":
				rows = self.accountMan.getAccountList()
				responseBody = self.SQLRowsToRecords(rows)
				contentType = "text/json"
			elif form == "json":
				rows = self.accountMan.getAccountList()
				responseBody = self.SQLRowsToJSON(rows)
				contentType = "text/json"
			else:
				status = "500 OK"
				responseBody = "Error: Invalid form: %s" % form
		
		headers = [('Content-type', contentType),
				   ('Content-Length', str(len(responseBody)))]
		return ServerResponse(status, headers, responseBody)
	
	def DEPgetAccountBuckets(self, query):
		#input("Press Enter to continue...")
		oldRows = []
		
		if query.get("account", -1) != -1:
			bucket = self.accountMan.getBucket(query["account"])
			oldRows = bucket.getAllChildren()
			if query.get("exclude", -1) == -1:
				oldRows.append(bucket)
		else:
			oldRows = self.accountMan.getAccountList() + self.accountMan.getBucketList()
			
		rows = oldRows
		
		#for row in oldRows:
		#	if query.get("exclude", None) == None or row.getID() != int(query["exclude"]):
		#		rows.append(row)
		
		responseBody = ""
		
		if query["format"] == "options":
			responseBody = self.SQLRowsToOptions(rows, "Name", "ID")
		elif query["format"] == "recordList":
			responseBody = self.SQLRowsToRecords(rows)
		elif query["format"] == "json":
			responseBody = self.SQLRowsToJSON(rows)
		else:
			responseBody = "Unknown format: %s" % query["format"]
		
		headers = [('Content-type', "text/json"),
				   ('Content-Length', str(len(responseBody)))]
		return ServerResponse("200 OK", headers, responseBody)
	
	def DEPgetAccountBucketsPOST(self, query, contentLen, content):
		return self.getAccountBuckets(query)
		
	def DEPgetBucketHierarchy(self, query):
		bucketID = query.get("bucket", None)
		responseBody = ""
		if bucketID is not None:
			if int(bucketID) == -1:
				buckets = self.accountMan.getAccountList()
				responseBody = self.SQLRowsToNodes(buckets)
			else:
				bucket = self.accountMan.getBucket(int(bucketID))
				responseBody = self.SQLRowsToNodes(bucket.getChildren())
				
		headers = [('Content-type', "text/json"),
				   ('Content-Length', str(len(responseBody)))]
		return ServerResponse("200 OK", headers, responseBody)
		
	def DEPupdateBucket(self, query, contentLen, content):
		formData = self.formToDict(content)
		bID = formData["ID"]
		bucket = self.accountMan.getBucket(bID)
		for i in formData.items():
			bucket.updateValue(i[0], i[1])
		responseBody = self.SQLRowToRecord(bucket)
		headers = [('Content-type', "text/json"),
		   ('Content-Length', str(len(responseBody)))]
		return ServerResponse("200 OK", headers, responseBody)
	
	def DEPdeleteBucket(self, query, contentLen, content):
		formData = self.formToDict(content)
		bID = formData["ID"]
		bucket = self.accountMan.getBucket(bID)
		self.accountMan.deleteBucket(bucket)
		responseBody = json.dumps({"Result": "OK"})
		headers = [('Content-type', "text/json"),
		   ('Content-Length', str(len(responseBody)))]
		return ServerResponse("200 OK", headers, responseBody)
	
	def DEPcreateBucket(self, query, contentLen, content):
		formData = self.formToDict(content)
		accountName = formData.get("Name")
		bucket = formData.get("Parent", -1)
		self.accountMan.createBucket(accountName, bucket)
		
		newID = -1
		for b in (self.accountMan.getAccountList() if bucket == -1 else self.accountMan.getBucketList()):
			if b.getName() == accountName:
				newID = b.getID()
				break
		
		newBucket = self.accountMan.getBucket(newID)
		responseBody = self.SQLRowToRecord(newBucket)
		headers = [('Content-type', "text/json"),
		   ('Content-Length', str(len(responseBody)))]
		return ServerResponse("200 OK", headers, responseBody)

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
		print("Using file handler for: %s" % path)
		try:
			# we try to serve up a file with the requested name
			#TODO: Make a more robust file handler
			typeGuess = mimetypes.guess_type(path)
			modeStr = "r%s" % ('t' if self.isText(typeGuess) else 'b')
			response_body = open("./" + path, mode=modeStr).read()
			status = '200 OK'
			headers = [('Content-type', typeGuess[0] if typeGuess[0] is not None else "application/octet-stream"),
				   ('Content-Length', str(len(response_body)))]

		except FileNotFoundError as e:
			response_body = "File not found"
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

server = SPENTServer(8080)
#server.open_browser()
server.start_server()