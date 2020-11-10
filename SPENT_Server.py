import mimetypes, json, time, os, sys
import traceback
from wsgiref.simple_server import make_server

from SPENT.DBBackup import backupDB
from SPENT.Old.SPENT import *
from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument("--file", dest="dbpath",
                    default="SPENT.db")
parser.add_argument("--root", dest="serverRoot",
                    default="./web")
parser.add_argument("--port", type=int, dest="port",
                    default=8080)
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
parser.add_argument("--serve-any",
					action="store_true", dest="serveAnyfile", default=False,
					help="Tell the file provider to serve any file requested")
parser.add_argument("--log-level",
					type=str, dest="logLevel", default="INFO",
					help="Sets the logging level (INFO, WARNING, ERROR, EXCEPTION, DEBUG)")

args = parser.parse_args()

srvlog = log.getLogger("SPENT Server")

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

class ServerResponse:
	def __init__(self, status, mimeType, headers, body):
		self.status = status
		self.headers = headers
		self.mtype = mimeType
		self.body = body

		self.encodedBody = None
		self.encodedHeaders = None

	def getStatus(self):
		return self.status

	def getHeaders(self):
		return self.headers

	def getBody(self):
		return self.body

	def getBodyAsString(self):
		if self.mtype == "text/json":
			return json.dumps(self.getBody(), indent=2)

		return str(self.getBody())

	def encode(self):
		self.encodeHeaders()
		self.encodeBody()

	def encodeHeaders(self):
		self.encodedHeaders = [('Content-type', self.mtype),
							   ('Content-Length',
								str(len(self.encodedBody)))] + self.headers if self.headers is not None else []

	def encodeBody(self):
		if isinstance(self.getBody(), bytes):
			self.encodedBody = self.getBody()
		elif self.mtype == "text/json":
			self.encodedBody = str.encode(json.dumps(self.getBody(), indent=2))
		else:
			self.encodedBody = str.encode(self.getBody())

	def getEncodedBody(self):
		return self.encodedBody

	def getEncodedHeaders(self):
		return self.encodedHeaders

	def __str__(self):
		return "%s %s\n%s" % (self.getStatus(), self.encodedHeaders, self.getBodyAsString())

class RequestHandler:
	def __init__(self, default):
		self.handlers = {}
		self.defaultHandler = default

	def registerRequestHandler(self, method, path, delegate):
		srvlog.debug("Registering endpoint backend: %s - %s" % (method, path))
		self.handlers["%s;%s" % (method, path)] = delegate

	def getHandler(self, method, path):
		srvlog.debug("Searching for endpoint backend for: %s - %s" % (method, path))
		return self.handlers.get("%s;%s" % (method, path), self.defaultHandler)

class EndpointBackend:
	pass

# We are ourself a backend so that we can support requests that change internal state
class SPENTServer(EndpointBackend):
	def __init__(self, port):
		log.setLevel(args.logLevel)
		self.port = port
		self.running = True

		# The file handler is the default and gets used when no other match is found
		fileEndpoint = FileEndpoint(args.serverRoot, args.serveAnyfile)
		fileEndpoint.registerFile("", "index.html", "text/html")
		fileEndpoint.registerFile("/css", "SPENT.css", "text/css")
		fileEndpoint.registerFile("/js", "SPENT.js", "text/javascript")
		fileEndpoint.registerFile("/js", "backbone-filtered-collection.js", "text/javascript")
		self.fileHandler = fileEndpoint
		self.handler = RequestHandler(self.fileHandler)

		dbEndpoint = DatabaseEndpoint(args.dbpath, args.debugAPI)
		self.handler.registerRequestHandler("POST", "/database/apiRequest", dbEndpoint)


		def getAvailBucketTreeBalance(args, connection):
			bucketID = args.get("bucket", None)
			bucket = EnumBucketsTable.getRow(connection, bucketID)
			print(bucket)
			if bucket is not None:
				return SpentUtil.getAvailableBalance(connection, bucket, True)
			return None

		def getPostedBucketTreeBalance(args, connection):
			bucketID = args.get("bucket", None)
			bucket = EnumBucketsTable.getRow(connection, bucketID)
			if bucket is not None:
				return SpentUtil.getPostedBalance(connection, bucket, True)
			return None

		def getAvailBucketBalance(args, connection):
			bucketID = args.get("bucket", None)
			bucket = EnumBucketsTable.getRow(connection, bucketID)
			if bucket is not None:
				return SpentUtil.getAvailableBalance(connection, bucket)
			return None

		def getPostedBucketBalance(args, connection):
			bucketID = args.get("bucket", None)
			bucket = EnumBucketsTable.getRow(connection, bucketID)
			if bucket is not None:
				return SpentUtil.getPostedBalance(connection, bucket)
			return None

		def propTest(args, connection):
			return "Test is good and successful"

		self.count = 0
		def counter(args, connection):
			self.count = self.count + 1
			return self.count

		propertyEndpoint = PropertyEndpoint(args.debugAPI, dbEndpoint.database)
		propertyEndpoint.registerProperty(Property("SPENT_bucket_availableTreeBalance", getAvailBucketTreeBalance, True))
		propertyEndpoint.registerProperty(Property("SPENT_bucket_postedTreeBalance", getPostedBucketTreeBalance, True))
		propertyEndpoint.registerProperty(Property("SPENT_bucket_availableBalance", getAvailBucketBalance, True))
		propertyEndpoint.registerProperty(Property("SPENT_bucket_postedBalance", getPostedBucketBalance, True))
		propertyEndpoint.registerProperty(Property("SPENT.property.test", propTest, False))
		propertyEndpoint.registerProperty(Property("vuex_counter", counter, False))
		self.handler.registerRequestHandler("POST", "/property/query", propertyEndpoint)

		enumEndpoint = EnumEndpoint(args.debugAPI)
		enumEndpoint.registerEnum("TransactionStatus", TransactionStatusEnum)
		enumEndpoint.registerEnum("TransactionType", TransactionTypeEnum)
		self.handler.registerRequestHandler("POST", "/enum/query", enumEndpoint)

	def handleRequest(self, environ, start_response):
		srvlog.debug("--------------------------------------------------------------------------------")
		runTime = ""
		method = environ['REQUEST_METHOD']
		path = environ['PATH_INFO']
		queryStr = self.qsToDict(environ['QUERY_STRING'])
		
		response = None
		try:
			# Search for a mapping
			delegate = self.handler.getHandler(method, path)
			skipResponse = False
			if delegate is not None:
				srvlog.debug("Using registered handler for: %s - %s" % (method, path))
				if method == 'POST':
					try:
						request_body_size = int(environ['CONTENT_LENGTH'])
						request_body = environ['wsgi.input'].read(request_body_size)

						# TODO: This assumes the post body is always json
						#if self.showAPIData:
						#	print("POST Request Body: \n%s" % json.dumps(json.loads(request_body), indent=2))

					except (TypeError, ValueError):
						request_body = "0"

					# Ask the delegate to handle the request
					resp = time_it(delegate.handlePostRequest, queryStr, request_body_size, request_body, path)
					response = resp[0]
					runTime = resp[1]
				else:
					resp = time_it(delegate.handleGetRequest, queryStr, path)
					response = resp[0]
					runTime = resp[1]
			else:
				srvlog.warning("Failed to find registered handler for: %s - %s" % (method, path))
				response = ServerResponse("404 OK", "text/text", None, "Invalid request: %s - %s" % (method, path))

		except Exception as e:
			srvlog.exception(e)
			response_body = "An unhandled exception occured!!\n"
			response_body += str(e) + "\n"
			response_body += traceback.format_exc()
			response = ServerResponse('500 OK', 'text/text', None, response_body)

		if response is None:
			response = ServerResponse('200 OK', 'text/text', None, "Handler returned no response")

		response.encode()
		start_response(response.getStatus(), response.getEncodedHeaders())

		#TODO: Reimplement this
		#if self.showAPIData:
		#	if not skipResponse:
		#		print("Server Response: %s" % sresponse)
		#	else:
		#		print("Server Response: -File-")
		
		# This should always print
		srvlog.debug("Request Delegate ran for: %s" % runTime)
		return [response.getEncodedBody()]

	def start_server(self):
		"""Start the server."""
		self.httpd = make_server("", self.port, self.handleRequest)
		print("Server is ready on port %s" % self.port)
		while self.running:
			self.httpd.handle_request()
	
	def qsToDict(self, queryString):
		result = {}
		spl = queryString.split("&")
		for i in spl:
			spl2 = i.split("=")
			if len(spl2) >= 2:
				result[str(spl2[0])] = str(spl2[1].replace("+", " "))

		srvlog.debug("QS To Dict: %s = %s" %(queryString, result))
		return result
	
	def formToDict(self, form):
		return self.qsToDict(form.decode("utf-8"))

class DatabaseEndpoint(EndpointBackend):
	def __init__(self, dbPath, debugAPI):
		# First things first... Backup, Backup, Backup!
		backupDB(["scriptname", dbPath, "SPENT.backup"])

		self.debugAPI = debugAPI
		self.database = sqlib.Database(SPENT_DB_V1, dbPath)
		self.connection = self.database.getConnection("Server")
		self.connection.connect()  # TODO: Implement a connection pool

		self.spentUtil = SpentUtil

		self.apiTree = {}
		self.apiTree["account"] = {"get": self.getFunction, "create": self.createFunction, "update": self.updateFunction, "delete": self.deleteFunction}
		self.apiTree["bucket"] = {"get": self.getFunction, "create": self.createBucketFunction, "update": self.updateFunction, "delete": self.deleteFunction}
		self.apiTree["transaction"] = {"get": self.getFunction, "create": self.createFunction, "update": self.updateFunction, "delete": self.deleteFunction}
		self.apiTree["transaction-group"] = {"get": self.getFunction, "create": self.createFunction, "update": self.updateFunction, "delete": self.deleteFunction}
		self.apiTree["debug"] = {"refresh": self.debugFunction}
		# self.apiTree["tag"] = {"get": self.getTag, "create": self.createTag, "update": self.updateTag, "delete": self.deleteTag} #Tags are handled differently

		self.typeMapper = {"account": EnumBucketsTable, "bucket": EnumBucketsTable, "transaction": EnumTransactionTable, "transaction-group": EnumTransactionGroupsTable, "tag": EnumTransactionTagsTable}
		self.reverseTypeMapper = {EnumBucketsTable: "account", EnumBucketsTable: "bucket", EnumTransactionTable: "transaction", EnumTransactionGroupsTable: "transaction-group", EnumTransactionTagsTable: "tag"}

	def debugFunction(self, request, columns, table, connection):
		srvlog.debug("Running debug function")
		return [{"id": 1,
				 "Status": 0,
				 "TransDate": "2020-12-12",
				 "PostDate": "2000-01-01",
				 "Amount": 3000000,
				 "SourceBucket": -1,
				 "DestBucket": 3,
				 "Memo": "The Test Worked!!",
				 "Payee": "Someone",
				 "GroupID": -1,
				 "IsTransfer": 0,
				 "Type": 0
				 }]

	def getDBConnection(self):
		return self.connection

	def handlePostRequest(self, query, contentLen, content, path):
		request = json.loads(content)
		responsePackets = []
		responseCode = "200 OK"

		if self.debugAPI:
			# This print is allowed to stay
			print(json.dumps(request, indent=2))

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

				srvlog.info("API Request: %s %s" % (packet["action"], packet["type"]))

				handlerFunc = typeDict.get(packet["action"], None)

				if handlerFunc is not None:
					requestedColumns = []

					if table is not None:
						requestedColumnsStr = self.getRequestedColumns(packet, table)
						requestedColumns = table.parseStrings(requestedColumnsStr)

					result = time_it(handlerFunc, packet, requestedColumns, table, connection)
					srvlog.debug("API Request Handler Ran For: %s" % result[1])

					if result[0] is not None:
						if packet["action"] == "refresh" and packet["type"] == "debug":
							packet["action"] = "update"
							packet["type"] = "transaction"

						pack = {"action": packet["action"], "type": packet["type"], "data": result[0]}
						if packet["type"] == "enum":
							pack["enum"] = packet.get("enum", None)
						responsePackets.append(pack)
				else:
					raise Exception(
						"Invalid action or type: (Action: %s, Type: %s)" % (packet["action"], packet["type"]))

		except Exception as e:
			changedState = connection.abortTransaction()
			changePackets = self.parseChangeState(changedState)
			responseCode = "500 OK"
			responseBody = {"successful": False, "message": "An exception occured while accessing the database: %s" % e,
							"records": changePackets}
			sqlog.exception(e)
		else:
			# TODO: Send back the things that changed
			changedState = connection.endTransaction()
			changePackets = self.parseChangeState(changedState)
			responseBody = {"successful": True, "records": responsePackets + changePackets}

		resp = ServerResponse(responseCode, "text/json", None, responseBody)
		if self.debugAPI:
			# This print is allowed to stay
			print(resp)
		return resp

	def parseChangeState(self, changeState):
		# print(changeState)
		packets = []
		map = {"create": "created", "update": "changed", "delete": "deleted"}
		for action in map.items():
			for item in changeState.get(action[1], {}).items():
				# print(item)
				table = item[0]
				data = item[1]

				if action[0] == "delete":
					idColumn = table.getIDColumn(table)
					data = [{idColumn.name: id} for id in data]

				if action[0] == "create":
					createdRowsSel = table.getRows(self.getDBConnection(), data)
					createdRows = createdRowsSel.getRows().values()
					data = [row.asDict() for row in createdRows]

				if action[0] == "update":
					newData = []
					for row in data.values():
						newRow = {}
						for i in row.items():
							newRow[i[0].name] = i[1]
						newData.append(newRow)
					data = newData

				packets.append({"action": action[0], "type": self.reverseTypeMapper[table], "data": data})

		srvlog.debug("Packets: " + str(packets))
		return packets

	def getRequestedColumns(self, request, table):
		data = request.get("columns", [])
		result = set(data)
		if len(result) > 0 and table.getIDColumn(table) is not None:
			result.add(table.getIDColumn(table))

		return result

	def getFunction(self, request, columns, table, connection):
		#TODO: Ths function needs to use the filter field as a "where"
		#TODO: Verify that the account table will only return accounts and the bucket table will not include accounts

		#TODO: RED ALERT! Taking a string from the request and feeding it into the query is very dangerous; This is only for testing
		whereStr = request.get("filter", None)
		if whereStr is None:
			data = request.get("data", {})
			where = self.dataToWhere(data, table.getIDColumn(table))
		else:
			where = SQL_WhereStatementBuilder(whereStr)
		selectedRows = table.select(connection, where)
		return self.SQLRowsToArray(selectedRows.getRows().values(), columns)

	def createBucketFunction(self, request, columns, table, connection):
		data = request.get("data", {})
		for obj in data:
			objData = self.parseSQLObjectToDict(table, obj)
			ancestor = self._genAncestor_(table, connection, None, objData.get(EnumBucketsTable.Parent))
			objData[EnumBucketsTable.Ancestor] = ancestor

			table.createRow(connection, objData)

		# This function sends no data back to the client because the list of created rows is sent elsewhere
		return None

	def _genAncestor_(self, table, connection, rowID, parentID):
		print("Gen Ancestor: %s, %s" % (rowID, parentID))
		if parentID is None or parentID == -1:
			print("Ancestor: %s" % rowID)
			return rowID

		# Else climb the tree
		row = table.getRow(connection, int(parentID))
		rowID = row.getID()
		parentID = row.getValue(EnumBucketsTable.Parent)
		return self._genAncestor_(table, connection, rowID, parentID)

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
		IDs = self.dataToIDList(data, idCol)
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

	def SQLRowsToArray(self, rows, columns=None):
		time = time_it(self.SQLRowsToArray_, rows, columns)
		srvlog.debug("Rows to Array ran for: " + time[1])

		return time[0]

	def SQLRowsToArray_(self, rows, columns=None):
		records = []

		srvlog.debug("Rows: %s, Columns: %s" % (rows, columns))
		for i in rows:
			if i is not None:
				records.append(i.asDict(columns))
			else:
				srvlog.error("SQLRowsToArray: Processed a None row!")
		return records

	def dataToIDList(self, data, idColumn):
		return [int(row.get(idColumn.name, -1)) for row in data if row.get(idColumn.name, -1) is not None]

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

	def closeDatabase(self, query):
		self.accountMan.disconnect()
		self.running = False

class FileEndpoint(EndpointBackend):
	def __init__(self, serverRoot, serveAny):
		srvlog.debug("Server Root is %s" % serverRoot)
		self.root = serverRoot
		self.files = {}
		self.serveAny = serveAny

	def registerFile(self, path, file, mime):
		srvlog.debug("File Backend: Registering file %s/%s - %s" % (path, file, mime))
		self.files["%s/%s" % (path, file)] = (path, file, mime)

	def isText(self, typeGuess):
		# print(typeGuess)
		# if typeGuess[0].startswith('text'):# or typeGuess[0].startswith('application/javascript'):
		#	return True

		return False

	def trimLeadingSlash(self, path):
		if path.startswith("/"):
			path = path[1:]  # Remove the leading /
		return path

	def handleGetRequest(self, query, path):
		if path == "/":
			path = "/index.html"

		srvlog.info("Using file handler for: %s" % path)

		path2 = path
		path = self.trimLeadingSlash(path)
		fullPath = os.path.join(self.root, path)
		srvlog.debug("Full file request path: %s" % fullPath)

		if self.serveAny:
			typeGuess = mimetypes.guess_type(fullPath)
			fileTuple = ("", "", typeGuess)
		else:
			fileTuple = self.files.get(path2, None)



		response_body = "File not found"
		status = '404 OK'
		mimeType = "text/plain"
		if fileTuple is not None:
			mimeType = fileTuple[2]
			try:
				typeGuess = mimeType
				modeStr = "r%s" % ('t' if self.isText(typeGuess) else 'b')
				response_body = open(fullPath, mode=modeStr).read()
				status = '200 OK'
				mimeType = typeGuess[0] if typeGuess[0] is not None else "application/octet-stream"

			except FileNotFoundError as e:
				if args.debugServer:
					response_body += "\n" + args.serverRoot + path + "\n"
					response_body += "\n".join(os.listdir(args.serverRoot))
		else:
			srvlog.warning("Unregistered file was requested: %s" % path)
		return ServerResponse(status, mimeType, None, response_body)

	def handlePostRequest(self, query, size, body, path):
		pass

class PropertyEndpoint(EndpointBackend):
	def __init__(self, debugAPI, database):
		self.debugAPI = debugAPI
		self.database = database
		self.propertyManager = PropertyManager()

	def registerProperty(self, property):
		self.propertyManager.registerProperty(property)

	def handleGetRequest(self, query, path):
		pass

	def handlePostRequest(self, query, size, content, path):
		request = json.loads(content)
		responsePackets = []

		if self.debugAPI:
			# This print is allowed to stay
			print(json.dumps(request, indent=2))

		connection = self.database.getConnection("Property Calc")
		connection.connect()
		for packet in request:
			action = packet.get("action", None)
			data = packet.get("data", [])

			if action is not None:
				props = []
				for item in data:
					if action == "get":
						property = self.getProperty(item, connection)
					elif action == "set":
						property = self.setProperty(item, connection)
					elif action == "refresh":
						property = self.debugFunction(item, connection)
						action = "get"
					else:
						pass

					if property is not None:
						props.append(property)

				responsePackets.append({"action": action, "type": "property", "data": props})
		connection.disconnect()

		responseBody = {"successful": True, "records": responsePackets}
		resp = ServerResponse("200 OK", "text/json", None, responseBody)
		if self.debugAPI:
			# This print is allowed to stay
			print(resp)
		return resp

	def debugFunction(self, property, connection):
		name = property.get("name", None)
		return {"name": name, "value": 10000.31}

	def getProperty(self, property, connection):
		name = property.get("name", None)
		if name is not None:
			#TODO: Allow some sort of arg passing
			prop = self.propertyManager.getProperty(name)
			if prop is not None:
				# TODO: "Smart" refresh rather than always refresh
				value = prop.refreshValue(property, connection)
				return {"name": prop.getPropertyName(), "value": value}
		return None

	def setProperty(self, property, connection):
		pass

class PropertyManager:
	def __init__(self):
		self.properties = {}

	def registerProperty(self, property):
		self.properties[property.getPropertyName()] = property

	def getProperty(self, name):
		pro = self.properties.get(name, None)
		if pro is None:
			logman.warning("Failed to find property with name \"%s\"" % name)
		else:
			logman.warning("Found property with name \"%s\"" % name)
		return pro

class Property:
	def __init__(self, name, calculatorFunction, needsConnection):
		self.name = name
		self._value_ = None
		self.calcFunc = calculatorFunction
		self.wantsDB = needsConnection

	def getPropertyName(self):
		return self.name

	def getValue(self):
		return self._value_

	def refreshValue(self, argsDict, connection):
		self._value_ = self.calculate(argsDict, connection)
		return self.getValue()

	def calculate(self, argsDict, connection):
		#logman.debug("Property.calculate() called!!")
		value = None
		try:
			if self.wantsDB:
				connection.beginTransaction()
			else:
				# This is for safety
				connection = None
			value = self.calcFunc(argsDict, connection)

			if self.wantsDB:
				connection.endTransaction()

		except Exception as e:
			srvlog.exception(e)
			if self.wantsDB:
				connection.abortTransaction()

		return value

class EnumEndpoint(EndpointBackend):
	def __init__(self, debug):
		self.enumRegistry = {}
		self.debugAPI = debug

	def registerEnum(self, enumName, enumObject):
		srvlog.debug("Enum Backend: Registering Enum %s - %s" % (enumName, enumObject))
		self.enumRegistry[enumName] = enumObject

	def handlePostRequest(self, query, size, content, path):
		request = json.loads(content)
		responsePackets = []

		if self.debugAPI:
			# This print is allowed to stay
			print(json.dumps(request, indent=2))

		for packet in request:
			enumName = packet.get("enum", None)
			if enumName is not None:
				enumValues = self.getEnum(enumName)
				if enumValues is not None:
					responsePackets.append({"action": "get", "type": "enum", "enum": enumName, "data": enumValues})

		responseBody = {"successful": True, "records": responsePackets}
		resp = ServerResponse("200 OK", "text/json", None, responseBody)
		if self.debugAPI:
			# This print is allowed to stay
			print(resp)
		return resp

	def getEnum(self, enumName):
		if enumName is not None:
			enumObj = self.enumRegistry.get(enumName, None)
			if enumObj is not None:
				enumConstList = enumObj.values(enumObj)
				print(enumConstList)
				data = [{"name": con[0], "value": con[1].value} for con in enumConstList]
				return data
		return None

if args.serverMode:
	if sys.hexversion >= 0x30001f0:
		print("Initializing Server")
		server = SPENTServer(args.port)
		#server.open_browser()
		print("Starting Server")
		server.start_server()
	else:
		print("Sorry, your version of python is too old")

# localhost:8080/database/query
# localhost:8080/files/$filename
# localhost:8080/property/query
# localhost:8080/enum/query