import sqlite3 as sql
import traceback, sys
from enum import Enum
from SPENT import LOGGER as log

log.initLogger()
logman = log.getLogger("Main")
sqldeb = log.getLogger("SQLIB Debug")
sqlog = log.getLogger("SQL Debug")
cadeb = log.getLogger("DB Cache Debug")

COLUMN_ANY = None

def printException(exception):
    desired_trace = traceback.format_exc()
    logman.exception(desired_trace)

#TODO: This should probably populate the dict using the table enum constants rather than strings
def sqlRowToDict(row, table):
    columnNames = [col for col in table]
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
        #TODO: Implement the verify functions for each type
        # (And change this to return False)
        return True

    def sanitize(self, data):
        # (And change this to "pass")
        return data

class StringTypeVerifier(TypeVerifier):
    pass

class IntegerTypeVerifier(TypeVerifier):
    def verify(self, value):
        return type(value) is int

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
        self.primaryKey = isPrimaryKey
        self.autoIncrement = autoIncrement
        self.keepUnique = keepUnique

    def getType(self):
        return self.type

    def willPreventNull(self):
        return self.preventNull

    def isPrimaryKey(self):
        return self.primaryKey

    def willAutoIncrement(self):
        return self.autoIncrement

    def willEnforceUnique(self):
        return self.keepUnique

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
        sqldeb.info("Initializing Column %s.%s; Type: %s" % (self.getTableName(), self.name, type(self.value)))
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

    def getRowClass(self):
        return TableRow

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

# RowSelection's selections are immutable
class RowSelection:
    def __init__(self, connection, table, rows, filter = None):
        self._connection_ = connection
        self._table_ = table

        # Rows is a dict; {Key: rowID, Value: TableRow}
        self.rows = rows
        self.filter = filter

    def getFilter(self):
        # We can't allow the authoritative record to be modified
        return self.filter.copy()

    def getRowIDs(self):
        # *.keys() takes the liberty of copying the data for us
        return self.rows.keys()

    def getValues(self, columnKey):
        # TODO: Add a means of getting all the columns without specifying each one
        # TODO: raise an exception if self.rows is None
        values = {}
        for row in self.rows.items():
            values[row[0]] = {columnKey: row[1].getValue(columnKey)}
        return values

    def setValues(self, columnKey, newValue):
        # TODO: raise an exception if self.rows is None
        for row in self.rows.values():
            row.setValue(columnKey, newValue)

    def getRows(self):
        #TODO: raise an exception if self.rows is None
        return self.rows.copy()

    def deleteRows(self):
        # TODO: While this function is running it must have exclusive access to self.rows and self.rowIDs
        for rowID in self.rows.keys():
            self._connection_.getDatabase()._getCache_().deleteRow(self._table_, self._connection_, rowID)
        oldRows = self.rows
        self.rows = None
        return oldRows

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
            sqldeb.debug("Cleaning old connection: %s" % name)
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
            logman.error("DatabaseConnection[\"%s\"]: Can't reopen a closed connection!!" % self.getName())
            return not connectionState

        if((self.connection is None) == (not connectionState)):
            return True
        else:
            logman.error(errorMessage)
            return False

    def _writeSchema_(self):
        sqldeb.debug("STUB: Writing schema to DB...")
        #TODO: Stub
        return True

    def getDatabase(self):
        return self.database

    def getName(self):
        return self.name

    def connect(self):
        if (self._assertDBConected_(False, errorMessage="Database is already connected")):
            logman.debug("DatabaseConnection[\"%s\"]: Opening connection to DB; Path: \"%s\"" % (self.getName(), self.database.getDBPath()))
            self.connection = sql.connect(self.database.getDBPath())
            if(self._writeSchema_()):
                self.connection.row_factory = sql.Row # test
            else:
                logman.error("Database File schema is incompatible with provided schema")
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
                sqlog.debug("DatabaseConnection[\"%s\"] Performing Query: %s" % (self.getName(), query))
                cur = self.connection.execute(query)
                return cur.fetchall()
            except Exception as e:
                printException(e)
                raise # We rethrow the exception so that the logic that triggered the error can handle the error

        sqlog.warning("Failed to execute query: %s" % query)
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
            idColumn = table.getIDColumn(table)
            id = row[idColumn.name]

            rowDataCache = self._getCachedRow_(id, table, row)
            rowClass = table.getRowClass(table)
            newRows.append(rowClass(rowDataCache))

        return newRows

    def _getCachedTable_(self, table):
        # Lazy init the table row dict
        tableCache = self.data.get(table.getTableName(table), None)
        if tableCache is None:
            tableCache = {}
            self.data[table.getTableName(table)] = tableCache
        return tableCache

    def _getCachedRow_(self, rowID, table, queryRow=None):
        cadeb.debug("Getting cached row %s" % rowID)
        # Returns the existing cached row and creates if non-existent
        tableCache = self._getCachedTable_(table)
        rowCache = tableCache.get(rowID, None)

        if rowCache is None and queryRow is not None:
            rowCache = RowDataCache(sqlRowToDict(queryRow, table), rowID)
            tableCache[rowID] = rowCache

        return rowCache

    def getRow(self, table, connection, rowID):
        cadeb.debug("%s@%s: Getting row: %s" % (connection.getName(), table.getTableName(table), rowID))

        # First get the row from the cache if it exists
        row = self._getCachedRow_(rowID, table)
        if row is None:
            # The row doesn't exist in the cache so we turn to the DB
            query = SQLQueryBuilder(EnumSQLQueryAction.SELECT).COLUMNS(COLUMN_ANY).FROM(table).WHERE_ID_IN([rowID])
            result = connection.execute(str(query))
            if len(result) < 1:
                # TODO: raise an excpetion or something
                cadeb.debug("%s@%s: No rows returned: %s" % (connection.getName(), table.getTableName(table), rowID))
                return None

            parsedRows = self._parseRows_(result, table)

            # TODO: Write logic to handle when (by some crazy sequence of events) more than one row is returned
            row = parsedRows[0]
        else:
            if row.isDeleted():
                return None
        return row

    def getRows(self, table, connection, rowIDs):
        cadeb.debug("%s@%s: Getting rows: %s" % (connection.getName(), table.getTableName(table), rowIDs))

        cacheRows = {}
        missingRows = []
        for id in rowIDs:
            # The value will be None if there is no cache entry for the row
            cacheRows[id] = self._getCachedRow_(id, table)
            if cacheRows[id] is None:
                missingRows.append(id)
            else:
                if cacheRows[id].isDeleted():
                    # We'll just pretend the row doesn't exist
                    del cacheRows[id] # Oops, clumsy fingers hit the delete button... Oh well..

        if len(missingRows) > 0:
            query = SQLQueryBuilder(EnumSQLQueryAction.SELECT).COLUMNS(COLUMN_ANY).FROM(table).WHERE_ID_IN(missingRows)
            result = connection.execute(str(query))
            if len(result) < 1:
                # TODO: raise an excpetion or something
                cadeb.error("%s@%s: No rows returned: %s" % (connection.getName(), table.getTableName(table), missingRows))

            parsedRows = self._parseRows_(result, table)
            rows = {}
            for row in parsedRows:
                rows[row.getRowID()] = row

            for id in missingRows:
                cacheRows[id] = rows.get(id, None)
                if cacheRows[id] is None:
                    cadeb.error("None row found!! ID: %s, Table: %s" % (id, table.getTableName(table)))
        return RowSelection(connection, table, cacheRows)

    def createRow(self, table, connection, rowData):
        cadeb.debug("%s@%s: Creating row: %s" % (connection.getName(), table.getTableName(table), rowData))
        pass

    def deleteRow(self, table, connection, rowID):
        cadeb.debug("%s@%s: Deleting row: %s" % (connection.getName(), table.getTableName(table), rowID))

        # Delete from the cache
        row = self._getCachedRow_(rowID, table)
        if row is not None:
            row._setDeleted_(True)

    def select(self, table, connection, filter):
        cadeb.debug("%s@%s:MOCK: Selecting rows: %s" % (connection.getName(), table.getTableName(table), filter))
        pass
        #return RowSelection(connection, table, filter)

    def flush(self):
        # TODO: Write all the pending changes to the database
        pass

class RowDataCache:
    def __init__(self, rowData, rowID):
        self._data_ = rowData
        self.id = rowID

        self.dirty = False
        self.deleted = False

    def isDirty(self):
        return self.dirty

    def _clearDirty_(self):
        self.dirty = False

    def isDeleted(self):
        return self.deleted

    def _setDeleted_(self, isDeleted):
        self.deleted = isDeleted

    def getID(self):
        return self.id

    def getValue(self, columnKey):
        value = self._data_.get(columnKey, null)
        if type(value) is not _NullValue_:
            return value
        cadeb.error("invalid key %s" % columnKey)
        return null

    def setValue(self, columnKey, value):
        oldValue = self.getValue(columnKey)
        if(type(oldValue) is not _NullValue_):
            if columnKey.value.getType().value.verify(value):
                self.dirty = True
                self._data_[columnKey] = columnKey.value.getType().value.sanitize(value)
                return oldValue
            else:
                cadeb.error("Invalid value %s for column %s" % (value, columnKey))
        else:
            # getValue already prints this error message
            pass
        #TODO: raise an exception if we get here

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
            columnStr = ", ".join([col.name for col in self.columns])
        else:
            columnStr = "*"

        idColumn = None
        if self.table is not None:
            idColumn = self.table.getIDColumn(self.table)
            fromStr = "FROM %s" % self.table.getTableName(self.table)

        if self.idList is not None and idColumn is not None:
            whereStr = "WHERE %s in (%s)" % (idColumn.name, ", ".join(map(str, self.idList)))

        queryStr = "%s %s %s %s" % (action, columnStr, fromStr, whereStr)
        return queryStr