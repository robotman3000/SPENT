import mimetypes, json, time, os, sys
import traceback
from wsgiref.simple_server import make_server
from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument("--file", dest="dbpath",
                    default="SPENT.db")
parser.add_argument("--use-dropbox",
                    action="store_true", dest="dropboxEnabled", default=False,
                    help="Enable syncing with dropbox")
parser.add_argument("--root", dest="serverRoot",
                    default="./web")
parser.add_argument("--port", type=int, dest="port",
                    default=8080)
#parser.add_argument("--debug",
#                    action="store_true", dest="debugCore", default=False,
#                    help="Enable debug logging")
parser.add_argument("--perf-mon",
                    action="store_true", dest="perfMon", default=False,
                    help="Enable performance logging")
parser.add_argument("--debug-API",
                    action="store_true", dest="debugAPI", default=False,
                    help="Enable API request logging")
parser.add_argument("--debug-Server",
                    action="store_true", dest="debugServer", default=False,
                    help="Enable server debugging features")
#parser.add_argument("--server-mode",
#					action="store_true", dest="serverMode", default=False,
#					help="Run the server")
parser.add_argument("--serve-any",
					action="store_true", dest="serveAnyfile", default=False,
					help="Tell the file provider to serve any file requested")
parser.add_argument("--log-level",
					type=str, dest="logLevel", default="INFO",
					help="Sets the logging level (INFO, WARNING, ERROR, EXCEPTION, DEBUG)")

args = parser.parse_args()

# We wait to import the SPENT libs because the constructors do a lot of work
# that doesn't need to happen if "--help" is passed.
from SPENT.DBBackup import backupDB
from SPENT.Util import *
from SPENT.SPENT_Schema_v1_1 import *
from SPENT.SQLIB import SQL_WhereStatementBuilder
from SPENT.DropboxSupport import *

srvlog = log.getLogger("SPENT.server")
log.getLogger("dropbox")
log.getLogger("urllib3.connectionpool")

log.setLevel(args.logLevel)

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
	def __init__(self, default=None):
		self.handlers = {}
		self.defaultHandler = default

	def registerRequestHandler(self, method, path, delegate):
		srvlog.debug("Registering endpoint backend: %s - %s" % (method, path))
		self.handlers["%s;%s" % (method, path)] = delegate

	def getHandler(self, method, path):
		srvlog.debug("Searching for endpoint backend for: %s - %s" % (method, path))
		return self.handlers.get("%s;%s" % (method, path), self.defaultHandler)

	def setDefaultHandler(self, handler):
		self.defaultHandler = handler

class EndpointBackend:
	def shutdown(self):
		pass

# We are ourself a backend so that we can support requests that change internal state
class SPENTServer(EndpointBackend):
	def __init__(self, port):
		self.port = port
		self.running = False
		self.handler = RequestHandler()

	def init_engine(self):

		# The file handler is the default and gets used when no other match is found
		fileEndpoint = FileEndpoint(args.serverRoot, args.serveAnyfile)
		fileEndpoint.registerFile("", "index.html", "text/html")
		fileEndpoint.registerFile("/css", "SPENT.css", "text/css")
		fileEndpoint.registerFile("/js", "SPENT.js", "text/javascript")
		self.fileHandler = fileEndpoint
		self.handler.setDefaultHandler(self.fileHandler)

		dbEndpoint = DatabaseEndpoint(args.dbpath, args.debugAPI)
		self.handler.registerRequestHandler("POST", "/database/apiRequest", dbEndpoint)

		def getAvailBucketTreeBalance(args, connection):
			bucketID = args.get("recordID", None)
			bucket = EnumBucketsTable.getRow(connection, bucketID)
			print(bucket)
			if bucket is not None:
				return SpentUtil.getAvailableBalance(connection, bucket, True)
			return None

		def getPostedBucketTreeBalance(args, connection):
			bucketID = args.get("recordID", None)
			bucket = EnumBucketsTable.getRow(connection, bucketID)
			if bucket is not None:
				return SpentUtil.getPostedBalance(connection, bucket, True)
			return None

		def getAvailBucketBalance(args, connection):
			bucketID = args.get("recordID", None)
			bucket = EnumBucketsTable.getRow(connection, bucketID)
			if bucket is not None:
				return SpentUtil.getAvailableBalance(connection, bucket)
			return None

		def getPostedBucketBalance(args, connection):
			bucketID = args.get("recordID", None)
			bucket = EnumBucketsTable.getRow(connection, bucketID)
			if bucket is not None:
				return SpentUtil.getPostedBalance(connection, bucket)
			return None

		def getTransactionTags(args, connection):
			transID = args.get("recordID", None)

			# Do we actually need to get the transaction
			# R/N we use this to ensure the requested transaction actually exists
			transaction = EnumTransactionTable.getRow(connection, transID)
			if transaction is not None:
				return SpentUtil.getTransactionTags(connection, transaction)
			return None

		def setTransactionTags(args, connection):
			transID = args.get("recordID", None)
			tags = args.get("tags", {})

			# Do we actually need to get the transaction
			# R/N we use this to ensure the requested transaction actually exists
			transaction = EnumTransactionTable.getRow(connection, transID)
			if transaction is not None:
				SpentUtil.setTransactionTags(connection, transaction, tags)

		propertyEndpoint = PropertyEndpoint(args.debugAPI, dbEndpoint.database)
		propertyEndpoint.registerProperty(LinkedProperty("SPENT.bucket.availableTreeBalance", getAvailBucketTreeBalance, True))
		propertyEndpoint.registerProperty(LinkedProperty("SPENT.bucket.postedTreeBalance", getPostedBucketTreeBalance, True))
		propertyEndpoint.registerProperty(LinkedProperty("SPENT.bucket.availableBalance", getAvailBucketBalance, True))
		propertyEndpoint.registerProperty(LinkedProperty("SPENT.bucket.postedBalance", getPostedBucketBalance, True))
		propertyEndpoint.registerProperty(LinkedMutableProperty("SPENT.transaction.tags", getTransactionTags, setTransactionTags, True))
		self.handler.registerRequestHandler("POST", "/property/query", propertyEndpoint)

		enumEndpoint = EnumEndpoint(args.debugAPI)
		enumEndpoint.registerEnum("TransactionStatus", TransactionStatusEnum)
		enumEndpoint.registerEnum("TransactionType", TransactionTypeEnum)
		self.handler.registerRequestHandler("POST", "/enum/query", enumEndpoint)

		self.endpoints = [fileEndpoint, dbEndpoint, propertyEndpoint, enumEndpoint]

	def handleRequest(self, environ, start_response):
		srvlog.debug("--------------------------------------------------------------------------------")
		runTime = "Not Measured"
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
					if args.perfMon:
						resp = time_it(delegate.handlePostRequest, queryStr, request_body_size, request_body, path)
						response = resp[0]
						runTime = resp[1]
					else:
						response = delegate.handlePostRequest(queryStr, request_body_size, request_body, path)

				else:
					if args.perfMon:
						resp = time_it(delegate.handleGetRequest, queryStr, path)
						response = resp[0]
						runTime = resp[1]
					else:
						response = delegate.handleGetRequest(queryStr, path)
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
		#while self.running:
		#	self.httpd.handle_request()
		self.httpd.serve_forever()

	def close_server(self):
		for ep in self.endpoints:
			ep.shutdown()
		self.httpd.shutdown()

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

		self.debugAPI = debugAPI
		self.database = sqlib.Database(SPENT_DB_V1_1, dbPath)
		self.connection = self.database.getConnection("Server")
		self.connection.connect()  # TODO: Implement a connection pool

		self.spentUtil = SpentUtil

		self.apiTree = {
			"account": {"get": self.getFunction, "create": self.createFunction, "update": self.updateFunction, "delete": self.deleteFunction},
			"bucket": {"get": self.getFunction, "create": self.createBucketFunction, "update": self.updateFunction, "delete": self.deleteFunction},
			"transaction": {"get": self.getFunction, "create": self.createFunction, "update": self.updateFunction, "delete": self.deleteFunction},
			"tag": {"get": self.getFunction, "create": self.createFunction, "update": self.updateFunction, "delete": self.deleteFunction},
			"tagMap": {"get": self.getFunction, "create": self.createFunction, "update": self.updateFunction, "delete": self.deleteFunction}
		}

		self.typeMapper = {"account": EnumBucketsTable, "bucket": EnumBucketsTable, "transaction": EnumTransactionTable, "tag": EnumTagsTable, "tagMap": EnumTransactionTagsTable}
		self.reverseTypeMapper = {v: k for k, v in self.typeMapper.items()}
			#{obj[1]: obj[0] for obj in self.typeMapper}

	def shutdown(self):
		self.database.closeDatabase()

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
			responseBody = {"successful": False, "message": "An exception occurred while accessing the database: %s" % e,
							"records": changePackets}
			srvlog.exception(e)
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
		print(changeState)
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
		if data is not None:
			for obj in data:
				if obj is not None:
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
		data = request.get("data", [])
		if data is None or len(data) < 1:
			# We return here because an empty selection is translated to mean every row in the table...
			# Not good when deleting
			return None

		idColumn = table.getIDColumn(table)
		where = self.dataToWhere(data, idColumn)
		selectedRows = table.select(connection, where)
		#if selectedRows is not None:
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

	def registerMutableProperty(self, property):
		self.propertyManager.registerMutableProperty(property)

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

	def getProperty(self, property, connection):
		name = property.get("name", None)
		if name is not None:
			#TODO: Allow some sort of arg passing
			prop = self.propertyManager.getProperty(name)
			if prop is not None:
				# TODO: "Smart" refresh rather than always refresh
				if isinstance(prop, LinkedProperty):

					# This record ID is used by the calculate functions of each property
					recordID = property.get("recordID", None)
					if recordID is None:
						raise Exception("No recordID was provided for LinkedProperty(\"%s\")" % prop.getPropertyName())
				prop.refreshValue(property, connection)
				val = prop.asDict(property)
				print(val)
				return val
		return None

	def setProperty(self, property, connection):
		name = property.get("name", None)
		if name is not None:
			# TODO: Allow some sort of arg passing
			prop = self.propertyManager.getMutableProperty(name)
			if prop is not None:
				# TODO: "Smart" refresh rather than always refresh
				if isinstance(prop, LinkedProperty):

					# Ensure the record ID was provided
					recordID = property.get("recordID", None)
					if recordID is None:
						raise Exception("No recordID was provided for LinkedProperty(\"%s\")" % prop.getPropertyName())
				prop.setValue(property, connection)
				return prop.asDict(property)
			else:
				print("Property %s is not mutable!!" % name)

		return None

class PropertyManager:
	def __init__(self):
		self.properties = {}
		self.mutableProperties = {}

	def registerProperty(self, property):
		self.properties[property.getPropertyName()] = property

	def registerMutableProperty(self, property):
		self.registerProperty(property)
		self.mutableProperties[property.getPropertyName()] = property

	def getProperty(self, name):
		pro = self.properties.get(name, None)
		if pro is None:
			logman.debug("Failed to find property with name \"%s\"" % name)
		else:
			logman.debug("Found property with name \"%s\"" % name)
		return pro

class Property:
	def __init__(self, name, calculatorFunction, needsConnection):
		self.name = name
		self._value_ = None
		self.calcFunc = calculatorFunction
		self.wantsDB = needsConnection

	def getPropertyName(self):
		return self.name

	def getTransportName(self):
		return self.getPropertyName()

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

	def asDict(self, argsDict):
		return {"name": self.getPropertyName(), "value": self.getValue()}

class LinkedProperty(Property):
	def __init__(self, name, calculatorFunction, needsConnection):
		super().__init__(name, calculatorFunction, needsConnection)

	def asDict(self, argsDict):
		return {"name": self.getPropertyName(), "value": self.getValue(), "recordID": argsDict.get("recordID", None)}

class MutableProperty(Property):
	def __init__(self, name, calculatorFunction, setterFunction, needsConnection):
		super().__init__(name, calculatorFunction, needsConnection)
		self.setterFunction = setterFunction

	def setValue(self, argsDict, connection):
		value = None
		try:
			if self.wantsDB:
				connection.beginTransaction()
			else:
				# This is for safety
				connection = None

			value = self.setterFunction(argsDict, connection)

			if self.wantsDB:
				connection.endTransaction()

		except Exception as e:
			srvlog.exception(e)
			if self.wantsDB:
				connection.abortTransaction()

		return value

class LinkedMutableProperty(MutableProperty):
	def __init__(self, name, calculatorFunction, setterFunction, needsConnection):
		super().__init__(name, calculatorFunction, setterFunction, needsConnection)

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

if __name__ == '__main__':
	if sys.hexversion >= 0x30001f0:
		try:
			# First we fetch the latest version of the db from dropbox
			# First things first, we have to ensure we have a database file
			# if we have one then we backup before doing anything else
			if os.path.exists(args.dbpath) and os.path.isfile(args.dbpath):
				# Backup, Backup, Backup!
				backupDB(["scriptname", args.dbpath, "SPENT.backup"])

			if args.dropboxEnabled:
				dbHelp = DropboxHelper(args.dbpath)
				dbHelp.sync_file(args.dbpath)
			# Else we do nothing because if the file doesn't exist SQLIB will create it for us

			print("Initializing Server")
			server = SPENTServer(args.port)
			server.init_engine()
			print("Starting Server")
			server.start_server()
		except KeyboardInterrupt as e:
			print("Exiting SPENT")
			server.close_server()

			# Sync the file to ensure changes are saved
			if args.dropboxEnabled:
				dbHelp.sync_file(args.dbpath)
			# Else we do nothing because if the file doesn't exist SQLIB will create it for us

			print("Goodbye!")
	else:
		print("Sorry, your version of python is too old")

# localhost:8080/database/query
# localhost:8080/files/$filename
# localhost:8080/property/query
# localhost:8080/enum/query