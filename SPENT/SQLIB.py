import sqlite3 as sql
import traceback, sys
from enum import Enum

COLUMN_ANY = None

def printException(exception):
    desired_trace = traceback.format_exc()
    print(desired_trace)

#TODO: This should probably populate the dict using the table enum constants rather than strings
def sqlRowToDict(row, table):
    columnNames = [col for col in table]
    #print(columnNames)
    dict = {}
    for column in columnNames:
        dict[column] = row[column.name]
    return dict

class test():
    def __init__(self, cursor, data):
        print(cursor)
        print([description[0] for description in cursor.description])
        print(data)
        print(sql.Row(cursor, data))
        print("------")

class TypeVerifier:
    def verify(self, data):
        pass

    def sanitize(self, data):
        pass

class StringTypeVerifier(TypeVerifier):
    pass

class IntegerTypeVerifier(TypeVerifier):
    pass

class DecimalTypeVerifier(TypeVerifier):
    pass

class DateTypeVerifier(TypeVerifier):
    pass

class EnumColumnType(Enum):
    TEXT = StringTypeVerifier()
    INTEGER = IntegerTypeVerifier()
    DECIMAL = DecimalTypeVerifier()
    DATE = DateTypeVerifier()

class TableRow():
    def __init__(self, rowDataCache):
        self.cache = rowDataCache

    def getRowID(self):
        return self.cache.getID()

    def getValue(self, columnKey):
        return self.cache.getValue(columnKey)

    def setValue(self, columnKey, newValue):
        return self.cache.setValue(columnKey, newValue)

class Column:
    def __init__(self, type, preventNull, isPrimaryKey, autoIncrement, keepUnique):
        self.type = type
        self.preventNull = preventNull
        self.isPrimaryKey = isPrimaryKey
        self.autoIncrement = autoIncrement
        self.keepUnique = keepUnique

    def getType(self):
        return self.type

    #TODO: get...() all the other properties

class TableColumn(Column):
    def __init__(self, type, preventNull, isPrimaryKey, autoIncrement, keepUnique, properties={}):
        super().__init__(type, preventNull, isPrimaryKey, autoIncrement, keepUnique)
        self.properties = properties

    def getProperties(self):
        # We copy to prevent the properties from being changed during runtime
        return self.properties.copy()

class VirtualColumn(Column):
    def __init__(self, type, valueFunction):
        super().__init__(type, False, False, False, False)
        self.valueFunction = valueFunction

    #TODO: Add support for caching the value of virtual columns
    def calculateValue(self):
        pass

class EnumTable(Enum):
    def __init__(self, column):
        print("Initializing Column %s.%s; Type: %s" % (self.getTableName(), self.name, type(self.value)))
        self.constraints = []
        #TODO: Handle virtual columns

    #TODO: This doesn't get called anywhere, but it should be used
    def P_writeTable_(self, connection):
        columns = []
        tableConstr = []
        for column in self.columns:
            options = []

            # TODO: There needs to be a better way of handling DB constraints
            if column.properties.get("isConstraint", False):
                tableConstr.append(column.get("constraintValue", None))
                continue

            if column.properties.get("PreventNull", False):
                options.append("NOT NULL")

            if column.properties.get("IsPrimaryKey", False):
                options.append("PRIMARY KEY")

            if column.properties.get("AutoIncrement", False):
                options.append("AUTOINCREMENT")

            if column.properties.get("KeepUnique", False):
                options.append("UNIQUE")

            # TODO: We should never access the column properties directly
            columns.append("\"%s\" %s %s" % (column.getName(), column.properties["type"], " ".join(options)))

        for constr in tableConstr:
            columns.append("CONSTRAINT %s" % constr)

        sqlStr = "CREATE TABLE IF NOT EXISTS \"%s\" (%s)" % (self.getName(), ", ".join(columns))

        #TODO: We do nothing with the returned cursor; it might need to be used for error checking
        connection.execute(sqlStr)

    def getTableName(self):
        return "UNNAMED_TABLE_ERROR"

    def getIDColumn(self):
        return None

    @classmethod
    def getRow(table, connection, rowID):
        return connection.getDatabase()._getCache_().getRow(table, connection, rowID)

    @classmethod
    def getRows(table, connection, rowIDs):
        return connection.getDatabase()._getCache_().getRows(table, connection, rowIDs)

    @classmethod
    def createRow(table, connection, rowData):
        return connection.getDatabase()._getCache_().createRow(table, connection, rowData)

    @classmethod
    def deleteRow(table, connection, rowID):
        return connection.getDatabase()._getCache_().deleteRow(table, connection, rowID)

    @classmethod
    def select(table, connection, filter):
        return connection.getDatabase()._getCache_().select(table, connection, filter)

class RowSelection:
    def __init__(self, filter):
        self.filter = filter
        self.rows = []
        self.refresh()

    def getValues(self):
        pass

    def setValues(self, columnKey, newValue):
        pass

    def getRows(self):
        return self.rows.copy()

    def deleteRows(self):
        pass

    # This re-runs the query used to get the selection
    # and updates the selections list of rows
    def refresh(self):
        pass

class Database:
    def __init__(self, dbPath=":memory:"):
        # Data storage
        self.path = dbPath
        self.connections = {}
        self.cache = DatabaseCacheManager()

    def _getCache_(self):
        return self.cache

    def getConnection(self, connectionName=""):
        # First we get the existing connection /w lazy init
        conn = self.connections.get(connectionName, None)
        if conn is None or conn._closed_:
            # We use this rather than .get(..., New Connection)
            # to avoid creating unnecessary objects
            # because Python init's the DatabaseConnection before calling get()
            # and only returns it if needed
            conn = DatabaseConnection(self, connectionName)

            # Store the new connection
            self.connections[connectionName] = conn

        # Then we clean out all the dead connections
        deadConnections = []
        for con in self.connections.items():
            if con[1] is None or con[1]._closed_:
                deadConnections.append(con[0])

        #We delete this way because dicts can't change size during iteration
        for name in deadConnections:
            print("Cleaning old connection: %s" % name)
            del self.connections[name]

        return conn

    def getDBPath(self):
        return self.path

class DatabaseConnection:
    def __init__(self, database, connectionName):
        self.connection = None
        self.database = database
        self.name = connectionName

        self._closed_ = False

    def _assertDBConected_(self, connectionState, errorMessage):
        if self._closed_:
            print("Error: DatabaseConnection[\"%s\"]: Can't reopen a closed connection!!" % self.getName())
            return not connectionState

        if((self.connection is None) == (not connectionState)):
            return True
        else:
            print("Error: %s" % errorMessage)
            return False

    def _writeSchema_(self):
        print("STUB: Writing schema to DB...")
        #TODO: Stub
        return True

    def getDatabase(self):
        return self.database

    def getName(self):
        return self.name

    def connect(self):
        if (self._assertDBConected_(False, errorMessage="Database is already connected")):
            print("Debug: DatabaseConnection[\"%s\"]: Opening connection to DB; Path: \"%s\"" % (self.getName(), self.database.getDBPath()))
            self.connection = sql.connect(self.database.getDBPath())
            if(self._writeSchema_()):
                self.connection.row_factory = sql.Row # test
            else:
                print("Error: Database File schema is incompatible with provided schema")
                # Now we disconnect to prevent the possibility of db corruption
                self.disconnect(False) # Do not commit; We want to leave the db untouched

    def disconnect(self, commit=True):
        if (self._assertDBConected_(True, errorMessage="Database is not connected")):
            if(commit):
                self.connection.commit()
            self.connection.close()
            self.connection = None
            self._closed_ = True

    #TODO: Check whether commit() will cause issues with the DatabaseCacheManager
    def commit(self):
        if (self._assertDBConected_(True, errorMessage="Database is not connected")):
            self.commit()

    def execute(self, query):
        if (self._assertDBConected_(True, errorMessage="Database is not connected")):
            try:
                print("Debug: DatabaseConnection[\"%s\"] Performing Query: %s" % (self.getName(), query))
                cur = self.connection.execute(query)
                #if(cur.description is not None):
                #    print([description[0] for description in cur.description])
                return cur.fetchall()
            except Exception as e:
                printException(e)
                raise # We rethrow the exception so that the logic that triggered the error can handle the error

        print("Failed to execute query: %s" % query)
        return None

class DatabaseCacheManager:
    # The cache implements a lazy fill pattern
    # We only add a row to the cache when it is first used

    def __init__(self):
        # {Key: tableKey, Value: {Key: rowID, Value: RowDataCache}}
        self.data = {}

        # This controls whether to delete/unallocate/garbage collect the cached rows after writing to the DB
        self._clearCacheOnWrite_ = False

    def _parseRows_(self, rows, table):
        # This function is responsible for converting sqlite3 Row objects into SQLIB TableRow objects
        newRows = []
        for row in rows:
            print("Parsing row")
            idColumn = table.getIDColumn(table)
            id = row[idColumn.name]

            rowDataCache = self._getCachedRow_(id, table, row)
            newRows.append(TableRow(rowDataCache))

        return newRows

    def _getCachedTable_(self, table):
        # Lazy init the table row dict
        tableCache = self.data.get(table.getTableName(table), None)
        if tableCache is None:
            tableCache = {}
            self.data[table.getTableName(table)] = tableCache
        return tableCache

    def _getCachedRow_(self, rowID, table, queryRow=None):
        print("Getting cached row %s" % rowID)
        # Returns the existing cached row and creates if non-existent
        tableCache = self._getCachedTable_(table)
        rowCache = tableCache.get(rowID, None)

        if rowCache is None and queryRow is not None:
            rowCache = RowDataCache(sqlRowToDict(queryRow, table), rowID)
            tableCache[rowID] = rowCache

        return rowCache

    def getRow(self, table, connection, rowID):
        print("%s@%s: Getting row: %s" % (connection.getName(), table.getTableName(table), rowID))

        # First get the row from the cache if it exists
        row = self._getCachedRow_(rowID, table)
        if row is None:
            # The row doesn't exist in the cache so we turn to the DB
            query = SQLQueryBuilder(EnumSQLQueryAction.SELECT).COLUMNS(COLUMN_ANY).FROM(table).WHERE_ID_IN([rowID])
            result = connection.execute(str(query))
            if len(result) < 1:
                # TODO: raise an excpetion or something
                print("%s@%s: No rows returned: %s" % (connection.getName(), table.getTableName(table), rowID))
                return None

            parsedRows = self._parseRows_(result, table)

            # TODO: Write logic to handle when (by some crazy sequence of events) more than one row is returned
            row = parsedRows[0]
        return row

    def getRows(self, table, connection, rowIDs):
        print("%s@%s: Getting rows: %s" % (connection.getName(), table.getTableName(table), rowIDs))
        pass

    def createRow(self, table, connection, rowData):
        print("%s@%s: Creating row: %s" % (connection.getName(), table.getTableName(table), rowData))
        pass

    def deleteRow(self, table, connection, rowID):
        print("%s@%s: Deleting row: %s" % (connection.getName(), table.getTableName(table), rowID))
        pass

    def select(self, table, connection, filter):
        print("%s@%s: Selecting rows: %s" % (connection.getName(), table.getTableName(table), filter))
        pass

class RowDataCache:
    def __init__(self, rowData, rowID):
        self.data = rowData
        self.id = rowID

        self.dirty = False

    def isDirty(self):
        return self.dirty

    def _clearDirty_(self):
        self.dirty = False

    def getValue(self, columnKey):
        #print("============")
        #print(self.data)
        value = self.data.get(columnKey, null)
        #print(type(value))
        if type(value) is not _NullValue_:
            return value
        print("Error: invalid key %s" % columnKey)
        return null

    def setValue(self, columnKey, value):
        oldValue = self.getValue(columnKey)
        if(type(oldValue) is not _NullValue_):
            if columnKey.value.getType().value.verify(value):
                self.dirty = True
                self.data[columnKey] = columnKey.value.getType().value.sanitize(value)
                return oldValue
            else:
                print("Error: Invalid value %s for column %s" % (value, columnKey))
        else:
            # getValue already prints this error message
            pass
        #TODO: raise an exception of we get here

class _NullValue_:
    pass
null = _NullValue_()

class EnumSQLQueryAction(Enum):
    SELECT = "SELECT"

class SQLQueryBuilder:
    def __init__(self, action):
        self.action = action
        self.table = None # FROM
        self.idList = None
        self.columns = None

    def COLUMNS(self, columnList):
        self.columns = columnList
        return self

    def FROM(self, tableKey):
        self.table = tableKey
        return self

    def WHERE_ID_IN(self, idList=[]):
        self.idList = idList
        return self

    def __str__(self):
        action = self.action.value
        columnStr = None
        fromStr = None
        whereStr = None

        if self.columns is not None and len(self.columns) > 0:
            columnStr = "".join([col.name for col in self.columns])
        else:
            columnStr = "*"

        idColumn = None
        if self.table is not None:
            #print(type(self.table))
            idColumn = self.table.getIDColumn(self.table)
            fromStr = "FROM %s" % self.table.getTableName(self.table)

        if self.idList is not None and idColumn is not None:
            whereStr = "WHERE %s in (%s)" % (idColumn.name, "".join(map(str, self.idList)))

        queryStr = "%s %s %s %s" % (action, columnStr, fromStr, whereStr)
        return queryStr