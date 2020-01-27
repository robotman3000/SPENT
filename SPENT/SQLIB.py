import sqlite3 as sql
import traceback, sys
from enum import Enum
from typing import Optional, List

from SPENT import LOGGER as log

log.initLogger()
logman = log.getLogger("Main")
sqldeb = log.getLogger("SQLIB Debug")
sqlog = log.getLogger("SQL Debug")
cadeb = log.getLogger("DB Cache Debug")

dbIndex = 0

COLUMN_ANY = None

def printException(exception):
    desired_trace = traceback.format_exc()
    logman.exception(desired_trace)

def sqlRowToDict(row, table):
    columnNames = [col for col in table]
    dict = {}
    for column in columnNames:
        if type(column.value) is TableColumn:
            dict[column] = row[column.name]
    return dict

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
    def __init__(self, rowDataCache, parentTable):
        self.cache = rowDataCache
        self.table = parentTable

    def getRowID(self):
        return self.cache.getID()

    def getValue(self, columnKey):
        if self.table.hasVirtualColumn(columnKey):
            #TODO: Cache virtual column values too
            return columnKey.value.calculateValue(self, self.table)
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

#TODO: Implement virtual columns
class VirtualColumn(Column):
    def __init__(self, type, valueFunction):
        super().__init__(type, False, False, False, False)
        self.valueFunction = valueFunction

    #TODO: Add support for caching the value of virtual columns
    def calculateValue(column, row, table):
        return "Hello World!"

class LinkedColumn(Column):
    pass

class EnumTable(Enum):
    def __init__(self, column):
        sqldeb.info("Initializing Column %s.%s; Type: %s" % (self.getTableName(), self.name, type(self.value)))

    #TODO: This doesn't get called anywhere, but it should be used
    def P_writeTable_(self, connection):
        columns = []
        tableConstr = []
        for obj in self.__members__.items():
            columnName = obj[0]
            column = obj[1]

            options = []
            if column.value.willPreventNull():
                options.append("NOT NULL")

            if column.value.isPrimaryKey():
                options.append("PRIMARY KEY")

            if column.value.willAutoIncrement():
                options.append("AUTOINCREMENT")

            if column.value.willEnforceUnique():
                options.append("UNIQUE")

            columns.append("\"%s\" %s %s" % (columnName, column.value.getType().name, " ".join(options)))

        for constr in self.getConstraints(self):
            columns.append("CONSTRAINT %s" % constr)

        sqlStr = "CREATE TABLE IF NOT EXISTS \"%s\" (%s)" % (self.getTableName(self), ", ".join(columns))

        #TODO: We do nothing with the returned cursor; it might need to be used for error checking
        connection.execute(sqlStr)
        #connection.commit()

    def getTableName(self):
        return "UNNAMED_TABLE_ERROR"

    def getIDColumn(self):
        return None

    def getRowClass(self):
        return TableRow

    def getConstraints(self):
        #List[str]
        return []

    @classmethod
    def P_isVirtualColumn_(table, columnKey):
        return type(columnKey.value) is VirtualColumn

    @classmethod
    def hasVirtualColumn(table, columnKey):
        if EnumTable.P_isVirtualColumn_(columnKey):
            if(table[columnKey.name] is not None):
                print("vir col found")
                return True
            else:
                print("Invalied col")
        else:
            sqldeb.warning("Attempted to get value of a non virtual column! Column: %s" % columnKey.name)
        return False

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

        global dbIndex
        self._index_ = dbIndex
        dbIndex += 1

        self.connection = self.getConnection("DB Internal")
        self.connection.connect()

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

    def initTable(self, table):
        return self._getCache_()._writeTable_(table, self.connection)

    def flush(self, connection):
        sqldeb.info("Writing cache to DB")
        self._getCache_()._writeCache_(connection)

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
        #TODO: This is where the database version will be compared to the schema version to determine they are compatable
        return True

    def getDatabase(self):
        return self.database

    def getName(self):
        return self.name

    def connect(self):
        if (self._assertDBConected_(False, errorMessage="Database is already connected")):
            logman.debug("DatabaseConnection[\"%s\"]: Opening connection to DB %s; Path: \"%s\"" % (self.getName(), self.getDatabase()._index_, self.database.getDBPath()))
            self.connection = sql.connect(self.database.getDBPath()) #TODO: This is incompatible with multiple connections to ":memory:"
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
            self.connection.commit()

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
            newRows.append(rowClass(rowDataCache, table))

        return newRows

    def _getCachedTable_(self, table):
        # Lazy init the table row dict
        tableCache = self.data.get(table, None)
        if tableCache is None:
            tableCache = {}
            self.data[table] = tableCache
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

    def _writeCache_(self, connection):
        for tableData in self.data.items():
            table = tableData[0]
            rowCache = tableData[1]

            if(self._verifyTable_(table, connection)):
                deletedRows = [] # This is a list of the row id's
                changedRows = [] # This is a list of the rows marked as dirty
                # This might need to be changed in the future; but right now new rows are commited at the time of creation
                # so there is no need to have a list of rows to commit
                # The issue with changing this is how to get a row id since that is handled automatically by sqlite3 through AUTOINCREMENT
                for rowData in rowCache.items():
                    id = rowData[0]
                    row = rowData[1]
                    if row.isDeleted():
                        deletedRows.append(id)
                    elif row.isDirty():
                        print("Found dirty row")
                        changedRows.append(id)

                # Now we construct a single query to do the delete and then the update
                # TODO: Create a single query that can update many rows with differing values

                delQuery = None
                if len(deletedRows) > 0:
                    delQuery = SQLQueryBuilder(EnumSQLQueryAction.DELETE).FROM(table).WHERE_ID_IN(deletedRows)

                updateQueries = []
                for id in changedRows:
                    updateQueries.append(SQLQueryBuilder(EnumSQLQueryAction.UPDATE).TABLE(table).SET(row._changed_()).WHERE_ID_IS(id))

                #TODO: Check the return values of these queries to ensure the cache remains consistent with the real DB
                # First the data updates
                #print(changedRows)
                for rowUpdateQuery in updateQueries:
                    connection.execute(str(rowUpdateQuery))

                # Then we demo everything slated for destruction
                if delQuery is not None:
                    connection.execute(str(delQuery))
            else:
                logman.error("Failed to write table %s schema to database!" % (table.getTableName(table)))

        if self._clearCacheOnWrite_:
            # This functions as a full cache reset
            # TODO: Consider implementing a partial cache clear
            self.data.clear()

    def _writeTable_(self, table, connection):
        table.P_writeTable_(table, connection)
        return self._verifyTable_(table, connection)

    def _verifyTable_(self, table, connection):
        # TODO: This is where we activly verify the table integrity and existence
        return True # TODO: Implement this

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

    def _changed_(self):
        # TODO: This should return the columns that changed not just everything
        cols = {}
        for item in self._data_.items():
            cols[item[0].name] = item[1]
        return cols

    def getID(self):
        return self.id

    def getValue(self, columnKey):
        #print(self._data_)
        value = self._data_.get(columnKey, null)
        if type(value) is not _NullValue_:
            return value

        cadeb.error("invalid key %s" % columnKey)
        return null

    def setValue(self, columnKey, value):
        oldValue = self.getValue(columnKey)
        if(type(oldValue) is not _NullValue_):
            if columnKey.value.getType().value.verify(value):
                print("Row is dirty")
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
    DELETE = "DELETE"
    UPDATE = "UPDATE"

class SQLQueryBuilder:
    def __init__(self, action):
        self.action = action
        self.table = None # FROM
        self.idList = None # Used for the where statement
        self.filter = None # Takes precedence over the idList
        self.columns = None # Used by select and similar
        self.updates = None # Used by UPDATE

    def SET(self, columnDict):
        self.updates = columnDict
        return self

    def COLUMNS(self, columnList):
        self.columns = columnList
        return self

    # This is syntactic sugar
    def TABLE(self, tableKey):
        return self.FROM(tableKey)

    def FROM(self, tableKey):
        self.table = tableKey
        return self

    def WHERE_ID_IN(self, idList=[]):
        self.idList = idList
        return self

    def WHERE_ID_IS(self, id):
        return self.WHERE_ID_IN([id])

    def WHERE(self, filter):
        self.filter = filter
        return self

    def __str__(self):
        useFROM = False
        useSET = False
        useWHERE = False

        action = self.action.value

        # switch like behavior with if's
        if self.action is EnumSQLQueryAction.SELECT:
            useFROM = True
            useWHERE = True

        if self.action is EnumSQLQueryAction.DELETE:
            useFROM = True
            useWHERE = True

        if self.action is EnumSQLQueryAction.UPDATE:
            useSET = True
            useWHERE = True

        idColumn = None
        fromStr = None
        if self.table is not None:
            idColumn = self.table.getIDColumn(self.table)

            if useFROM:
                fromStr = "FROM %s" % self.table.getTableName(self.table)
            else:
                fromStr = "%s" % self.table.getTableName(self.table)
        else:
            sqldeb.error("No table defined!")
            return None

        whereStr = None
        if useWHERE:
            #TODO: Consider adding a feature to merge the where filter and the id list so both can be used in the same query
            if self.filter is not None:
                # Filters have highest priority
                whereStr = str(self.filter)
            elif self.idList is not None and idColumn is not None:
                # Do we have an id list?
                compareString = ""
                ids = ", ".join(map(str, self.idList))
                if len(self.idList) > 1:
                    compareString = "in (%s)" % ids
                else:
                    compareString = "= %s" % ids

                whereStr = "WHERE %s %s" % (idColumn.name, compareString)

        columnStr = None
        if useSET:
            if self.updates is not None:
                updList = []
                for i in self.updates.items():
                    if idColumn is not None and i[0] == idColumn.name:
                        continue

                    if i[0] is not None:
                        value = ""
                        if type(value) is str:
                            value = "\"%s\"" % i[1]
                        else:
                            value = i[1]
                        updList.append("%s = %s" % (i[0], value))

                columnStr = "SET %s" % ", ".join(updList)
            else:
                sqldeb.error("No updates defined!")
                return None
        else:
            if self.columns is not None and len(self.columns) > 0:
                columnStr = ", ".join([col.name for col in self.columns])
            else:
                columnStr = "*"

        queryStr = None
        if self.action is EnumSQLQueryAction.SELECT:
            queryStr = "%s %s %s %s" % (action, columnStr, fromStr, whereStr)

        if self.action is EnumSQLQueryAction.DELETE:
            queryStr = "%s %s %s" % (action, fromStr, whereStr)

        if self.action is EnumSQLQueryAction.UPDATE:
            queryStr = "%s %s %s %s" % (action, fromStr, columnStr, whereStr)

        sqldeb.debug("Generated query string = \"%s\"" % queryStr)
        return queryStr

#TODO: Replace the string based builder with an object based builder
class SQL_WhereStatementBuilder():
    def __init__(self, initialStatement: Optional[str] = None):
        # Note: The list datatype must maintain the order the elements are added
        self.logic: List[BooleanStatement] = []
        if initialStatement is not None:
            self.addStatement("AND", initialStatement)

    def addStatement(self, operation: str, expression: str) -> 'SQL_WhereStatementBuilder':
        self.logic.append(BooleanStatement(operation, expression))
        return self

    def insertStatement(self, operation: str, expression: str) -> 'SQL_WhereStatementBuilder':
        self.logic.insert(0, BooleanStatement(operation, expression))
        return self

    def AND(self, expression: str) -> 'SQL_WhereStatementBuilder':
        return self.addStatement("AND", expression)

    def OR(self, expression: str) -> 'SQL_WhereStatementBuilder':
        return self.addStatement("OR", expression)

    def __str__(self) -> str:
        strs = []
        for i in range(len(self.logic)):
            if i > 0:
                strs.append(self.logic[i].getOperation() + " ")
            strs.append(self.logic[i].getExpression())

        return ("" if len(strs) < 1 else "WHERE " + " ".join(strs))

class BooleanStatement():
    def __init__(self, operation: str, expression: str):
        self.operation = operation
        self.expression = expression

    def getOperation(self) -> str:
        return self.operation

    def getExpression(self) -> str:
        return self.expression

    def __str__(self) -> str:
        return "BooleanStatement: %s %s" % (self.operation, self.expression)
