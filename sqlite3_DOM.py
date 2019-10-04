import sqlite3 as sql
import sys
import traceback
def Aprint(*args, **kwargs):
	"""My custom print() function."""
	#__builtin__.print('My overridden print() function!')
	#return __builtin__.print(*args, **kwargs)
	return True
	
class DatabaseWrapper():
	#TODO: create an api for getting the value of a single cell
	def __init__(self, dbPath):
		self.con = None
		self.dbPath = dbPath
		self.printDebug = False
		self.schema = {}
		self.enums = {}
		self.virtualColumns = {}

	def _getLastInsRowID_(self):
		return self._rawSQL_("SELECT last_insert_rowid()")[0]
		
	def _rawSQL_(self, command):
		return self._rawSQLList_([command])
	
	def _rawSQLList_(self, commands):
		result = []
		cursor = self.con.cursor()
		if cursor is not None and commands is not None:
			try:
				for cmd in commands:
					if self.printDebug:
						print("Debug: SQL: %s" % cmd)
					if cmd is not None:
						cursor.execute(cmd)
					else:
						print("Error: DatabaseWrapper._rawSQLList_: Recieved None CMD")
			except Exception as e:
				print("Error: SQL: %s" % e)

			while True:
				row = cursor.fetchone()
				if row is None:
					break;
				result.append(row)
				if self.printDebug:
					print("Debug: SQL: %s" % str(row))
			cursor.close()
		else:
			print("Error: DatabaseWrapper._rawSQLList_: Recieved None Input")
		return result
	
	def _tableSelectDelete_(self, isDelete, tableName, columnNames=["*"], where=None):
		#TODO: Support a list of rows rather than all or one
		if not (isDelete is None or tableName is None or columnNames is None):
			command = "DELETE" if isDelete else ("SELECT %s" % ", ".join(columnNames))
			query = "%s FROM %s" % (command, tableName)

			if where is not None:
				query += " %s" % where

			result = self._rawSQL_(query)
			rows = self.parseRows(result, columnNames, tableName)
			return rows
		else:
			print("Error: DatabaseWrapper._tableSelectDelete_: Recieved None Input")
		return []
		
	def parseRows(self, rows, columnNames=["*"], tableName=None):
		names = columnNames
		parsedRows = []
		
		if not (rows is None and columnNames is None):
			if (len(columnNames) == 1 and columnNames[0] =="*"):
				tableSchema = self.getTableSchema(tableName)
				if len(tableSchema) > 0:
					# Use the declared columns
					temp = []
					for i in tableSchema:
						n = i.get("name", None)
						if n is not None:
							temp.append(n)
					names = temp
				else:
					#TODO: Should pragma even be allowed here?
					# Use pragma to get the column names
					temp = self._rawSQL_("PRAGMA table_info(%s)" % tableName)
					temp2 = [""] * len(temp)
					for i in temp:
						# i[0] is the column index
						# i[1] is the column name
						temp2[i[0]] = i[1]

					names = temp2

			#print("Names: %s" % names)
			for i in rows:
				columns = {}
				for x in range(0, len(names)):
					if i is None or names[x] is None or len(i) < x:
						print("Error: DatabaseWrapper.parseRows: Found None value in column parse loop")
						continue
					columns[names[x]] = i[x]
				parsedRows.append(SQL_Row(self, columns, tableName))
		else:
			print("Error: DatabaseWrapper.parseRows: Recieved None Input")
		return parsedRows
		
	def quoteStr(self, value):
		if isinstance(value, str):
			return "\"%s\"" % value
		return str(value)
		
	def _tableInsertInto_(self, tableName, columns, replace = False):
		keyList = []
		valueList = []
		if columns is not None:
			keyList = columns.keys()
			valueList = columns.values()
		else:
			print("Error: DatabaseWrapper._tableInsertInto_: columns was None")
		keyStr = ", ".join(keyList)
		
		valueStr = ", ".join(map(self.quoteStr, valueList))
		self._rawSQL_("%s INTO %s (%s) VALUES (%s)" % (("REPLACE" if replace else "INSERT"), tableName, keyStr, valueStr))
		return self._getLastInsRowID_()
		
	def updateTableRow(self, tableName, columns, rowID):
		self.updateTableWhere(tableName, columns, self.rowsToWhere([rowID]))
		
	def updateTableWhere(self, tableName, columns, where):
		updateList = []
		if columns is not None:
			for i in columns.items():
				updateList.append("%s = %s" % (i[0], self.quoteStr(i[1])))
		else:
			print("Error: DatabaseWrapper.updateTableWhere: Recieved None Columns")
			
		if where is None:
			where = ""
			print("Error: DatabaseWrapper.updateTableWhere: where was None")
			
		updates = ", ".join(updateList)
		query = "UPDATE %s SET %s %s" % (tableName, updates, where)
		self._rawSQL_(query)
		
	def connect(self):
		self.con = sql.connect(self.dbPath)
		self.initTables()
	
	def disconnect(self):
		self.save()
		self.con.close()
		
	def save(self):
		self.con.commit()
		
	def initTables(self):
		#TODO: Verify the input data
		#TODO: Check if any of the "enum" tables need their data corrected
		# if so then verify the integrity and consistency of the data
		
		if len(self.schema) < 1:
			print("Error: Database.initTables: No Tables Registered")
		
		for schema in self.schema.items():
			tableName = schema[0]
			columns = []
			defs = []
			if schema[1] is not None:
				# Normal Table
				defs = schema[1]
			else:
				# Enum Table
				defs = [{"name": "ID", "type": "INTEGER", "PreventNull": True, "IsPrimaryKey": True, "AutoIncrement": False, "KeepUnique": True},
			 			{"name": "Name", "type": "TEXT", "PreventNull": True, "IsPrimaryKey": False, "AutoIncrement": False, "KeepUnique": True}]
				
			for column in defs:
				options = []
				if column.get("PreventNull", False):
					options.append("NOT NULL")

				if column.get("IsPrimaryKey", False):
					options.append("PRIMARY KEY")

				if column.get("AutoIncrement", False):
					options.append("AUTOINCREMENT")

				if column.get("KeepUnique", False):
					options.append("UNIQUE")

				columns.append("\"%s\" %s %s" % (column["name"], column["type"], " ".join(options)))
				
			sqlStr = "CREATE TABLE IF NOT EXISTS \"%s\" (%s)" % (tableName, ", ".join(columns))
			self._rawSQL_(sqlStr)
			
			enumValues = self.enums.get(tableName, [])
			for index in range(len(enumValues)):
				self._tableInsertInto_(tableName, {"ID" : index, "Name" : enumValues[index]}, True)
		
	def selectTableRow(self, tableName, rowID):
		return self.selectTableRowColumns(tableName, rowID)
		
	def selectTableColumn(self, tableName, columnName="*"):
		return self.selectTableColumns(tableName, [columnName])
		
	def selectTableColumns(self, tableName, columnNames=["*"]):
		return self.selectTableRowsColumns(tableName, columnNames=columnNames)
	
	def selectTableRowColumn(self, tableName, rowID, columnName="*"):
		return self.selectTableRowColumns(tableName, rowID, [columnName])
	
	def selectTableRowColumns(self, tableName, rowID, columnNames=["*"]):
		return self.selectTableRowsColumns(tableName, [rowID], columnNames)
	
	def selectTableRowsColumns(self, tableName, rowIDs=[], columnNames=["*"]):
		return self.selectTableRowsColumnsWhere(tableName, columnNames, self.rowsToWhere(rowIDs))
		
	def selectTableRowsColumnsWhere(self, tableName, columnNames=["*"], where=None):
		return self._tableSelectDelete_(False, tableName, columnNames, where)

	def deleteTableRow(self, tableName, rowID):
		return self.deleteTableRows(tableName, [rowID])

	def deleteTableRows(self, tableName, rowIDs=[]):
		whereStatement = self.rowsToWhere(rowIDs)
		return self.deleteTableRowsWhere(tableName, whereStatement)

	def deleteTableRowsWhere(self, tableName, where):
		return self._tableSelectDelete_(True, tableName, where=where)
		
	def rowsToWhere(self, rowIDs):
		whereStatement = SQL_WhereStatementBuilder()
		if rowIDs is not None:
			for row in rowIDs:
				if row is not None:
					whereStatement.OR("ID == %d" % int(row))
				else:
					traceback.print_stack()
					print("Error: Database.rowsToWhere: id was NOne")
		else:
			print("Error: DatabaseWrapper.rowsToWhere: rowIDs was None")
		return whereStatement
	
	def remapValue(self, tableName, inColumn, outColumn, oldValue):
		#TODO: Verify the input data
		result = self._rawSQL_("SELECT %s FROM %s WHERE %s == \"%s\"" % (outColumn, tableName, inColumn, oldValue))
		if len(result) > 0:
			return result[0][0]
		return None
	
	def registerTableSchemaColumnProperty(self, tableName, columnName, propertyName, value):
		#TODO: Verify the input data
		for i in self.getTableSchema(tableName):
			if i["name"] == columnName:
				props = i.get("properties", None)
				if props is None:
					i["properties"] = {}
					
				i["properties"][propertyName] = value
	
	def getTableColumnProperty(self, tableName, columnName, propertyName):
		for i in self.getTableSchema(tableName):
			if i["name"] == columnName:
				return i.get("properties", {}).get(propertyName, None)

	def registerVirtualColumn(self, tableName, columnName, virtualFunction):
		#TODO: Verify the input data
		print("Registering Virtual Column: %s.%s" % (tableName, columnName))
		
		virCols = self.virtualColumns.get(tableName, None)
		if virCols is None:
			self.virtualColumns[tableName] = {}
		
		self.virtualColumns[tableName][columnName] = virtualFunction
		
	def getTableVirtualColumns(self, tableName):
		return self.virtualColumns.get(tableName, {})
	
	def registerTableSchema(self, tableName, schema, enumValues = None):
		#TODO: Verify the input data
		print("Registering Table: %s" % tableName)
		self.schema[tableName] = schema
		if enumValues is not None:
			self.schema[tableName] = None # So we have full control over the enum table
			self.enums[tableName] = enumValues
	
	def getTableSchema(self, tableName):
		return self.schema.get(tableName, [])
	
class SQL_Row():
	def __init__(self, database, columns, tableName, virtualColumns = None):
		#TODO: Verify the input data
		self.database = database
		self.columns = columns
		self.tableName = tableName
		self.columnNameList = [i["name"] for i in self.database.getTableSchema(self.tableName)]
		
	def __str__(self):
		return str(self.columns)
	
	def getTableName(self):
		return self.tableName

	def getColumn(self, columnName):
		if self.database.printDebug:
			print("Debug: SQL_Row.getColumn: %s" % columnName)
		column = self.getColumnIndex(columnName)
		schema = self.database.getTableSchema(self.getTableName())
		if len(schema) > column:
			return schema[column]
		print("Error: SQL_Row.getColumn: Column %s has index of %s, the schema for %s has a size of %s" % (columnName, column, self.getTableName(), len(schema)))
		#traceback.print_stack()
		return {}
		
	def getColumnIndex(self, columnName):
		names = self.getColumnNames()
		for i in range(len(names)):
			if names[i] is not None and names[i] == columnName:
				if self.database.printDebug:
					print("Debug: SQL_Row.getColumnIndex: Names: %s, Index: %s, Name: %s" % (names, i, columnName))
				return i
				
		print("Error: SQL_Row.getColumnIndex: Invalid column name: %s" % columnName)
		traceback.print_stack()
		return -1
	
	def getColumnName(self, index):
		names = self.getColumnNames()
		if index < len(names):
			return names[index]
		print("Error: SQL_Row.getColumnName: Column index %s is greater than max of %s" % (index, len(names)))
		return ""
	
	def getColumnNames(self, includeVirtual=True):
		#TODO: Verify there are no None values running loose in here
		#TODO: This is supposd to maintain order and append all non duplicate virtual column names to the end
		# THis is n*m complexity? anyway it is about the slowest way to do the job; so this needs redone
		result = []
		for x in self.columnNameList:
			result.append(x)
		
		for x in self.database.getTableVirtualColumns(self.getTableName()).items():
			if not self._isValueInList_(x[0], self.columnNameList):
				result.append(x[0])
				
		return result
	
	def _isValueInList_(self, value, checkList):
		for i in checkList:
			if value == i:
				return True
		return False
	
	def getColumnProperty(self, columnName, propertyName):
		return self.getColumn(columnName).get(propertyName, None)
	
	def _getValue_(self, columnName):
		return self.columns.get(columnName, None)
	
	def getValue(self, columnName, force=False, defaultValue=None):
		if self.getColumnIndex(columnName) > -1 or force:
			virCol = self.database.getTableVirtualColumns(self.getTableName()).get(columnName, None)
			if virCol is not None:
				return virCol(self, self.getTableName(), columnName)

			return self._getValue_(columnName)
		return defaultValue
		
	def getValues(self, columnNames):
		result = []
		colNames = columnNames
		if columnNames is None:
			colNames = self.getColumnNames()
		for i in colNames:
			result.append(self.getValue(i))
		return result
		
class SQL_RowMutable(SQL_Row):
	def __init__(self, database, tableName, rowID):
		super().__init__(database, {}, tableName)
		#TODO: Raise an exception if the rowID is None or is not an int
		if rowID is not None:
			self.id = rowID
		else:
			print("Error: SQL_RowMutable.__init__: rowID cannot be None")
	
	def refreshColumns(self):
		result = self.database.selectTableRow(self.getTableName(), self.id)
		self.columns = result[0].columns
		
	def getValue(self, columnName):
		self.refreshColumns()
		return super().getValue(columnName)
	
	def getValues(self, columnNames):
		#TODO: Add logic to determine when to update self.columns
		self.refreshColumns()
		return super().getValues(columnNames)
	
	def updateValue(self, columnName, value):
		self.updateValues({columnName : value})
	
	def updateValues(self, columns):
		if columns is not None:
			for i in columns.items():
				if i is not None:
					self.database.updateTableRow(self.tableName, columns, self.id)
				else:
					print("Error: SQL_RowMutable.updateValues: A colum item was None")
		else:
			print("Error: SQL_RowMutable.updateValues: columns can't be None")
			
	def getValueRemapped(self, columnName):
		#TODO: Verify that there are no None's where they shouldn't be
		self.refreshColumns()
		oldValue = self.getValue(columnName)
		remapKeyBase = self.getColumnProperty(columnName, "remapKey")
		if remapKeyBase is not None:
			temp2 = remapKeyBase.split(":")
			tabName = temp2[0]
			return self.database.remapValue(tabName, temp2[1], temp2[2], oldValue)
			
		if self.database.printDebug and oldValue is None:
			print("Debug: SQL_RowMutable: Returning None for %s" % columnName)
			
		return oldValue
	
	def getColumnsRemapped(self):
		#TODO: Verify there are no None's where there shouldn't be
		result = {}
		for i in self.columns.items():
			result[i[0]] = self.getValueRemapped(i[0])
		return result
	
	def __str__(self):
		self.refreshColumns()
		return str(self.getColumnsRemapped())
		
class SQL_WhereStatementBuilder():
	def __init__(self, initialStatement=None):
		# Note: The list datatype must maintain the order the elements are added
		self.logic = []
		if initialStatement is not None:
			self.addStatement("", initialStatement)
		
	def addStatement(self, operation, expression):
		newOp = operation
		if len(self.logic) == 0:
			newOp = ""
			
		self.logic.append(BooleanStatement(newOp, expression))
		return self
	
	def AND(self, expression):
		return self.addStatement("AND", expression)
	
	def OR(self, expression):
		return self.addStatement("OR", expression)
		
	def __str__(self):
		strs = []
		for i in self.logic:
			strs.append(str(i))
		return ("" if len(strs) < 1 else "WHERE " + " ".join(strs))
	
class BooleanStatement():
	def __init__(self, operation, expression):
		self.operation = operation
		self.expression = expression
		
	def __str__(self):
		return "%s %s" % (self.operation, self.expression)
