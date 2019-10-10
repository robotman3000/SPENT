import sqlite3 as sql
import sys
import traceback
from typing import List, Set, Dict, Tuple, Optional, Any, Union
	
class DatabaseWrapper():
	#TODO: create an api for getting the value of a single cell
	def __init__(self, dbPath: str):
		self.con = None
		self.dbPath: str = dbPath
		self.printDebug: bool = False
		self.schema: Dict[str, Dict[str, Union[str, bool]]] = {}
		self.enums: Dict[str, Dict[str, int]] = {}
		self.virtualColumns: Dict[str, Dict[str, function]] = {}

	def _getLastInsRowsID_(self):
		return self._rawSQL_("SELECT last_insert_rowid()", False)
		
	def _rawSQL_(self, command: str, sugar: bool = True) -> List[sql.Row]:
		return self._rawSQLList_([command], sugar)
	
	def _rawSQLList_(self, commands, sugar=True):
		if sugar:
			print("Warn: DatabaseWrapper._rawSQLList_: This shouldn't be called directly")
			
		result = []
		cursor = self.con.cursor()
		if cursor is not None and commands is not None:
			try:
				for cmd in commands:
					if self.printDebug:
						print("Debug: SQL Request: %s" % cmd)
					if cmd is not None:
						cursor.execute(cmd)
					else:
						print("Warn: DatabaseWrapper._rawSQLList_: Recieved None CMD")
			except Exception as e:
				#TODO: This should use a more specific type
				raise e
				#print("Error: SQL: %s" % e)
			
			for row in cursor:
				result.append(row)
				if self.printDebug:
					print("Debug: SQL Response: %s" % str(row))
			
			if self.printDebug and len(result) < 1:
				print("Debug: SQL Response: Empty")
				
			cursor.close()
		else:
			print("Warn: DatabaseWrapper._rawSQLList_: Recieved None Input")
		return result
	
	def _tableSelectDelete_(self, isDelete, tableName, columnNames=["*"], where=None):
		if not (isDelete is None or tableName is None or columnNames is None):
			command = "DELETE" if isDelete else ("SELECT %s" % ", ".join(columnNames))
			query = "%s FROM %s" % (command, tableName)

			if where is not None:
				query += " %s" % where

			result = self._rawSQL_(query, False)
			rows = self.parseRows(result, columnNames, tableName)
			return rows
		else:
			print("Warn: DatabaseWrapper._tableSelectDelete_: Recieved None Input")
		return []
		
	def parseRows(self, rows, columnNames=["*"], tableName=None):
		names = columnNames
		parsedRows = []
		
		if not (rows is None and columnNames is None):
			if len(rows) > 0:
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
						temp = self._rawSQL_("PRAGMA table_info(%s)" % tableName, False)
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
							print("Warn: DatabaseWrapper.parseRows: Found None value in column parse loop")
							continue
						columns[names[x]] = i[x]
					parsedRows.append(SQL_Row(self, columns, tableName))
		else:
			print("Warn: DatabaseWrapper.parseRows: Recieved None Input")
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
		self._rawSQL_("%s INTO %s (%s) VALUES (%s)" % (("REPLACE" if replace else "INSERT"), tableName, keyStr, valueStr), False)
		return self._getLastInsRowsID_()
		
	def updateTableRow(self, tableName, columns, rowID):
		return self.updateTableWhere(tableName, columns, self.rowsToWhere([rowID]))
		
	def updateTableWhere(self, tableName, columns, where):
		updateList = []
		if columns is not None:
			virColumns = self.getTableVirtualColumns(tableName)
			for i in columns.items():
				if virColumns.get(i[0], None) is None:
					updateList.append("%s = %s" % (i[0], self.quoteStr(i[1])))
				else:
					#TODO: This should probably raise a ValueError rather than silently failing
					print("Warn: DatabaseWrapper.updateTableWhere: Attempted to update a virtual column: Table: %s, Column: %s" % (tableName, i[0]))
		else:
			print("Warn: DatabaseWrapper.updateTableWhere: Recieved None Columns")
			
		if where is None:
			where = ""
			print("Warn: DatabaseWrapper.updateTableWhere: where was None")
			
		if len(updateList) > 0:
			updates = ", ".join(updateList)
			query = "UPDATE %s SET %s %s" % (tableName, updates, where)
			return self._rawSQL_(query, False)
		return []
		
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
			self._rawSQL_(sqlStr, False)
			
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
			rowStr = ", ".join(map(str, rowIDs))
			whereStatement.AND("ID in (%s)" % rowStr)
		else:
			print("Warn: DatabaseWrapper.rowsToWhere: rowIDs was None")
		return whereStatement
	
	def remapValue(self, tableName, inColumn, outColumn, oldValue):
		if self.printDebug:
			print("Remapping Value: %s" % oldValue)
		#TODO: Verify the input data
		result = self._rawSQL_("SELECT %s FROM %s WHERE %s == \"%s\"" % (outColumn, tableName, inColumn, oldValue), False)
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
			pass
			#print("Debug: SQL_Row.getColumn: %s" % columnName)
		column = self.getColumnIndex(columnName)
		if column > -1:
			schema = self.database.getTableSchema(self.getTableName())
			if len(schema) > column:
				return schema[column]
			print("Warn: SQL_Row.getColumn: Column %s has index of %s, the schema for %s has a size of %s" % (columnName, column, self.getTableName(), len(schema)))
			#traceback.print_stack()
		else:
			print("Warn: SQL_Row.getColumn: Invalid column name %s in table %s; Returning None" % (columnName, self.getTableName()))
		return None
		
	def getColumnIndex(self, columnName):
		names = self.getColumnNames(True)
		for i in range(len(names)):
			if names[i] is not None and names[i] == columnName:
				if self.database.printDebug:
					pass
					#print("Debug: SQL_Row.getColumnIndex: Names: %s, Index: %s, Name: %s" % (names, i, columnName))
				return i
				
		raise ValueError("SQL_Row.getColumnIndex: Invalid column name: %s" % columnName)
	
	def getColumnName(self, index):
		names = self.getColumnNames(True)
		if index < len(names):
			return names[index]
		print("Warn: SQL_Row.getColumnName: Column index %s is greater than max of %s" % (index, len(names)))
		return ""
	
	def getColumnNames(self, includeVirtual=True):
		#TODO: Verify there are no None values running loose in here
		#TODO: This is supposd to maintain order and append all non duplicate virtual column names to the end
		# This is n*m complexity? anyway it is about the slowest way to do the job; so this needs redone
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
		column = self.getColumn(columnName)
		if column is not None:
			return column.get(propertyName, None)
		raise ValueError("SQLRow.getColumnProperty: Invalid column name: %s" % columnName)
	
	def getValue(self, columnName, force=False, defaultValue=None):
		if self.getColumnIndex(columnName) > -1 or force:
			virCol = self.database.getTableVirtualColumns(self.getTableName()).get(columnName, None)
			if virCol is not None:
				return virCol(self, self.getTableName(), columnName)

			return self.columns.get(columnName, None)
		return defaultValue
		
	def getValues(self, columnNames):
		result = []
		colNames = columnNames
		if columnNames is None:
			colNames = self.getColumnNames(True)
		for i in colNames:
			result.append(self.getValue(i))
		return result
		
class SQL_RowMutable(SQL_Row):
	def __init__(self, database, tableName, rowID):
		super().__init__(database, {}, tableName)
		#TODO: Raise an exception if the rowID is None or is not an int
		if type(rowID) is int:
			self.id = rowID
			self.isDirty = True
			self.refreshColumns()
		else:
			raise ValueError("SQL_RowMutable.__init__: rowID must be an int not %s" % type(rowID))
	
	def _isDirty_(self):
		return self.isDirty
		
	def _markClean_(self, newValue=False):
		self.isDirty = newValue
		
	def refreshColumns(self):
		if self._isDirty_():
			if self.database.printDebug:
				print("Refresh Columns")

			result = self.database.selectTableRow(self.getTableName(), self.id)
			
			#self._markClean_()
			
			if self.database.printDebug:
				print("Refreshed")

			if len(result) > 0:
				self.columns = result[0].columns
			else:
				raise ValueError("SQL_RowMutable.refreshColumns: No records returned for table %s and ID %s" % (self.getTableName(), self.id))
		
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
					print("Warn: SQL_RowMutable.updateValues: A column item was None")
		else:
			print("Warn: SQL_RowMutable.updateValues: columns can't be None")
			
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
			self.addStatement("AND", initialStatement)
		
	def addStatement(self, operation, expression):
		self.logic.append(BooleanStatement(operation, expression))
		return self
	
	def insertStatement(self, operation, expression):
		self.logic.insert(0, BooleanStatement(operation, expression))
		return self
	
	def AND(self, expression):
		return self.addStatement("AND", expression)
	
	def OR(self, expression):
		return self.addStatement("OR", expression)
		
	def __str__(self):
		strs = []
		for i in range(len(self.logic)):
			if i > 0:
				strs.append(self.logic[i].getOperation() + " ")
			strs.append(self.logic[i].getExpression())
			
		return ("" if len(strs) < 1 else "WHERE " + " ".join(strs))
	
class BooleanStatement():
	def __init__(self, operation, expression):
		self.operation = operation
		self.expression = expression
		
	def getOperation(self):
		return self.operation
	
	def getExpression(self):
		return self.expression
		
	def __str__(self):
		return "BooleanStatement: %s %s" % (self.operation, self.expression)
