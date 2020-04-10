import mimetypes, json, time, os
from wsgiref.simple_server import make_server
from SPENT.Old.SPENT import *
from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument("--file", dest="dbpath",
                    default="SPENT.db")
parser.add_argument("--root", dest="serverRoot",
                    default="./web")
#parser.add_argument("--debug",
#                    action="store_true", dest="debugCore", default=False,
#                    help="Enable debug logging")
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
		self.database = sqlib.Database(args.dbpath)
		self.connection = self.database.getConnection("Server")
		self.connection.connect() #TODO: Implement a connection pool

		self.spentUtil = SpentUtil

		self.showAPIData = args.debugAPI
		
		self.port = port

		self.handler = RequestHandler()
		self.handler.registerRequestHandler("POST", "/database/apiRequest", self.apiRequest)

		self.apiTree = {}
		self.apiTree["account"] = {"get": self.getFunction, "create": self.createFunction, "update": self.updateFunction, "delete": self.deleteFunction}
		self.apiTree["bucket"] = {"get": self.getFunction, "create": self.createFunction, "update": self.updateFunction, "delete": self.deleteFunction}
		self.apiTree["transaction"] = {"get": self.getFunction, "create": self.createFunction, "update": self.updateFunction, "delete": self.deleteFunction}
		self.apiTree["transaction-group"] = {"get": self.getFunction, "create": self.createFunction, "update": self.updateFunction, "delete": self.deleteFunction}
		#self.apiTree["tag"] = {"get": self.getTag, "create": self.createTag, "update": self.updateTag, "delete": self.deleteTag} #Tags are handled differently
		#self.apiTree["property"] = {"get": self.getProperty, "update": self.updateProperty}
		#self.apiTree["enum"] = {"get": self.getEnum}

		self.typeMapper = {"account" : EnumBucketsTable, "bucket" : EnumBucketsTable, "transaction": EnumTransactionTable, "transaction-group": EnumTransactionGroupsTable, "tag": EnumTransactionTagsTable}

	def getDBConnection(self):
		return self.connection

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
				#TODO: Add a list of "registered" files that the server is allowed to serve
				resp = time_it(self.handler.fileHandler, queryStr, path)
				response = resp[0]
				runTime = resp[1]
				skipResponse = True

		except Exception as e:
			response_body = "An unhandled exception occured!!\n"
			response_body += str(e) + "\n"
			response_body += traceback.format_exc()
			#print(response_body)
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
				
		#self.accountMan.save()
		
		# This should always print
		print("Request Delegate ran for: %s" % runTime)
		return [response.getBody()]
		
	def apiRequest(self, query, contentLen, content):
		request = json.loads(content)
		responsePackets = []
		responseCode = "200 OK"

		# This function is responsible for every request against the database
		# so we start by getting a connection (for the db) and ensuring that it
		# is ready for use
		connection = self.getDBConnection()
		if not connection.isConnected():
			connection.connect()

		# We can assume that if connect() ran without an exception then we are ready to talk to the db
		connection.beginTransaction()
		try:
			for packet in request:
				typeDict = self.apiTree.get(packet["type"], {})
				table = self.typeMapper.get(packet["type"], None)

				print("API Request: %s %s" % (packet["action"], packet["type"]))

				handlerFunc = typeDict.get(packet["action"], None)

				if handlerFunc is not None:
					requestedColumnsStr = self.getRequestedColumns(packet, table)
					requestedColumns = table.parseStrings(requestedColumnsStr)

					result = time_it(handlerFunc, packet, requestedColumns, table, connection)
					if args.debugServer:
						print("API Request Handler Ran For: %s" % result[1])

					if result[0] is not None:
						responsePackets.append({"action": packet["action"], "type": packet["type"], "data": result[0]})
				else:
					raise Exception("Invalid action or type: (Action: %s, Type: %s)" % (request["action"], request["type"]))

		except Exception as e:
			connection.abortTransaction()
			responseCode = "500 OK"
			responseBody = json.dumps({"successful": False, "message": "An exception occured while accessing the database: %s" % e})
			sqlog.exception(e)
		else:
			#TODO: Send back the things that changed
			connection.endTransaction()
			responseBody = json.dumps({"successful": True, "records": responsePackets}, indent=2)

		headers = [('Content-type', "text/json"),
				   ('Content-Length', str(len(responseBody)))]
		return ServerResponse(responseCode, headers, responseBody)
	
	def getRequestedColumns(self, request, table):
		data = request.get("columns", [])
		result = set(data)
		if len(result) > 0 and table.getIDColumn(table) is not None:
			result.add(table.getIDColumn(table))

		return result
	
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
		
	def SQLRowsToArray(self, rows, columns=None):
		time = time_it(self.SQLRowsToArray_, rows, columns)
		if args.debugServer:
			print("Rows to Array ran for: " + time[1])
			
		return time[0]
	
	def SQLRowsToArray_(self, rows, columns=None):
		records = []
		
		if args.debugServer:
			print("Rows: %s, Columns: %s" % (rows, columns))
		for i in rows:
			if i is not None:
				records.append(i.asDict(columns))
			else:
				print("Error: SQLRowsToArray: Processed a None row!")
		return records

	def dataToIDList(self, data, idColumn):
		return [int(row.get(idColumn, -1)) for row in data if row.get(idColumn, -1) is not None]

	def dataToWhere(self, data, idColumn):
		if data is not None and len(data) > 0:
			rowList = self.dataToIDList(data, idColumn)
			return SQL_WhereStatementBuilder("%s in (%s)" % (idColumn.name, ", ".join(map(str, rowList))))
		return SQL_WhereStatementBuilder()

	def parseSQLObjectToDict(self, table, obj):
		# Translate the string names into their object mapping
		columns = table.parseStrings(obj.keys())

		# Note: There is no need to clean the values or check them for validity because
		# SQLIB does that for us using the schema definition

		# Note: There is no need to verify that all the required columns are present because
		# SQLIB does that for us and will raise an exception of there is a problem

		objData = {col: obj.get(col.name) for col in columns}
		return objData

	def wrapData(self, data):
		return {"successful": True, "data": data}
		
	def closeDatabase(self, query):
		self.accountMan.disconnect()
		self.running = False

	def getFunction(self, request, columns, table, connection):
		#TODO: Ths function needs to use the filter field as a "where"
		# TODO: Verify that the account table will only return accounts and the bucket table will not include accounts
		data = request.get("data", {})
		where = self.dataToWhere(data, table.getIDColumn(table))
		selectedRows = table.select(connection, where)
		return self.SQLRowsToArray(selectedRows.getRows().values(), columns)

	def createFunction(self, request, columns, table, connection):
		data = request.get("data", {})
		for obj in data:
			objData = self.parseSQLObjectToDict(table, obj)
			table.createRow(connection, objData)

		# This function sends no data back to the client because the list of created rows is sent elsewhere
		return None

	def updateFunction(self, request, columns, table, connection):
		data = request.get("data", {})
		idCol = table.getIDColumn(table)
		IDs = self.dataToIDList(data, idCol.name)
		selection = table.getRows(connection, IDs)
		for obj in data:
			rowID = obj.get(idCol.name, None)
			if rowID is not None:
				# If the client provided an id for this object
				row = selection.getRow(rowID)
				if row is not None:
					# and the id is valid
					# then perform the update
					objData = self.parseSQLObjectToDict(table, obj)
					row.setValues(objData)
		return None

	def deleteFunction(self, request, columns, table, connection):
		data = request.get("data", {})
		where = self.dataToWhere(data, table.getIDColumn(table))
		selectedRows = table.select(connection, where)
		selectedRows.deleteRows()

		# This function sends no data back to the client because the list of deleted rows is sent elsewhere
		return None

	def getTag(self, request, columns):
		pass

	def createTag(self, request, columns):
		pass

	def updateTag(self, request, columns):
		pass

	def deleteTag(self, request, columns):
		pass

	def getProperty(self, request, columns):
		pass
	
	def updateProperty(self, request, columns):
		pass
	
	def getEnum(self, request, columns):
		pass

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
		return "%s %s\n%s" % (self.getStatus(),
							  self.getHeaders(),
							  json.dumps(json.loads(self.getBody()), indent=2))
	
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
