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

#def printException(exception):
#    desired_trace = traceback.format_exc()
#    logman.exception(desired_trace)

def sqlRowToDict(row, table):
    columnNames = [col for col in table]
    dict = {}
    for column in columnNames:
        if type(column.value) is TableColumn or type(column.value) is LinkedColumn:
            dict[column] = row[column.name]
    return dict

class TypeVerifier:
    # This verifies that "data" can be represented in the implementation type
    def verify(self, data):
        return False

    # This converts the data to the impl type
    def sanitize(self, data):
        sqldeb.warning("TypeVerifier.sanitize() was called!!!")
        return None

class StringTypeVerifier(TypeVerifier):
    def verify(self, data):
        # Everything can be a string
        return True

    def sanitize(self, data):
        if type(data) is str:
            return data

        return str(data)

class IntegerTypeVerifier(TypeVerifier):
    def verify(self, value):
        # TODO: is int or can be converted to int
        return type(value) is int

    def sanitize(self, data):
        # Ensure the data is an int
        if type(data) is int:
            return data

        return int(data)

class DecimalTypeVerifier(TypeVerifier):
    #TODO: Implement this and fix integer to only allow whole numbers
    pass

class DateTypeVerifier(TypeVerifier):
    pass

class EnumColumnType(Enum):
    TEXT = StringTypeVerifier()
    INTEGER = IntegerTypeVerifier()
    #DECIMAL = DecimalTypeVerifier()
    DATE = DateTypeVerifier()

class TableRow():
    def __init__(self, rowDataCache, parentTable):
        self.cache = rowDataCache
        self.table = parentTable

        idCol = self.table.getIDColumn(self.table)
        self.id = self.cache.getValue(idCol)

    def getRowID(self):
        return self.id

    def getValue(self, columnKey):
        if self.table.hasVirtualColumn(columnKey):
            #TODO: Cache virtual column values too
            return columnKey.value.calculateValue(self, self.table)
        return self.cache.getValue(columnKey)

    def setValue(self, columnKey, newValue):
        return self.cache.setValue(columnKey, newValue)

    def setValues(self, data):
        # Note: This function does not return the old values
        for i in data.items():
            self.setValue(i[0], i[1])

    def getColumns(self):
        return self.table.getColumns(self.table)

    def asDict(self, columns=None):
        data = {}
        colList = []
        if columns is not None and len(columns) > 0:
            colList = columns
        else:
            colList = self.getColumns()

        for col in colList:
            data[col.name] = self.getValue(col)

        return data

    def __str__(self):
        return str(self.cache)

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

    def verify(self, value):
        sqldeb.debug("Column %s verifying %s" % (self, value))
        return True

    def sanitize(self, value):
        sqldeb.debug("Column %s sanitizing %s" % (self, value))
        return value

    def getTable(self):
        return self.table

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
    def calculateValue(column, row, table):
        data = column.valueFunction(row, table, column)
        if column.getType().value.verify(data):
            return column.getType().value.sanitize(data)

class LinkedColumn(TableColumn):
    def __init__(self, type, preventNull, isPrimaryKey, autoIncrement, keepUnique, properties={}, foreignKey=None, localKey=None):
        super().__init__(type, preventNull, isPrimaryKey, autoIncrement, keepUnique, properties)
        if (foreignKey is None and localKey is None) or (foreignKey is not None and localKey is not None):
            raise Exception("Linked columns must have one defined key")

        if foreignKey is not None:
            self.key = foreignKey
        else:
            self.key = localKey

    def getReferenceKey(self):
        return self.key

    def getReferenceTable(self):
        if type(self.key) is Column:
            return self.key.getTable()
        return self.getTable()

    def isLocal(self):
        return type(self.key) is str

class EnumTable(Enum):
    def __init__(self, column):
        sqldeb.info("Initializing Column %s.%s; Type: %s" % (self.getTableName(), self.name, type(self.value)))
        column.table = self

    def P_writeTable_(self, connection):
        columns = []
        foreignKeys = []
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

            if type(column.value) is LinkedColumn:
                table = column.value.getReferenceTable()
                foreignColumnName = column.value.getReferenceKey()
                if not column.value.isLocal():
                    foreignColumnName = foreignColumnName.name

                #TODO: Verify that the column exists in the referenced table
                #column = table[foreignColumnName]  # This will trigger an exception if the column doesn't exist

                foreignKeys.append("FOREIGN KEY(%s) REFERENCES %s(%s)" % (columnName,
                                                                      table.getTableName(),
                                                                      foreignColumnName))

        for constr in self.getConstraints(self):
            columns.append("CONSTRAINT %s" % constr)

        sqlStr = "CREATE TABLE IF NOT EXISTS \"%s\" (%s)" % (self.getTableName(self), ", ".join(columns + foreignKeys))

        #TODO: We do nothing with the returned cursor; it might need to be used for error checking

        #TODO: Verify that this code will properly handle rolling back in the event of an error
        try:
            connection.execute(sqlStr)
        except Exception as e:
            sqlog.exception(e)

        #connection.commit()

    def onInit(self, connection):
        sqldeb.debug("Init called on EnumTable!!")

    def getTableName(self):
        return "UNNAMED_TABLE_ERROR"

    def getIDColumn(self):
        return None

    def getRowClass(self, rowData):
        return TableRow

    def getConstraints(self):
        #List[str]
        return []

    def getColumns(self):
        return self.__members__.values()

    @classmethod
    def parseStrings(table, columnNames):
        # This function converts a list of strings into a list of the columns that match the strings by name
        # It quietly drops any strings that don't have a matching column
        result = []
        for column in table.__members__.values():
            #print(column)
            if column.name in columnNames:
                result.append(column)

        return result

    @classmethod
    def P_isVirtualColumn_(table, columnKey):
        return type(columnKey.value) is VirtualColumn

    @classmethod
    def hasVirtualColumn(table, columnKey):
        if EnumTable.P_isVirtualColumn_(columnKey):
            if(table[columnKey.name] is not None):
                # Then we found a virtual column
                return True
        return False

    @classmethod
    def getRow(table, connection, rowID):
        if connection.canExecuteSafe():
            return connection.getDatabase()._getCache_().getRow(table, connection, rowID)
        else:
            raise Exception("Database is locked")

    @classmethod
    def getRows(table, connection, rowIDs):
        if connection.canExecuteSafe():
            return connection.getDatabase()._getCache_().getRows(table, connection, rowIDs)
        else:
            raise Exception("Database is locked")

    @classmethod
    def createRow(table, connection, rowData):
        if connection.canExecuteUnsafe():
            return connection.getDatabase()._getCache_().createRow(table, connection, rowData)
        else:
            raise Exception("Database is locked")

    @classmethod
    def deleteRow(table, connection, rowID):
        if connection.canExecuteUnsafe():
            return connection.getDatabase()._getCache_().deleteRow(table, connection, rowID)
        else:
            raise Exception("Database is locked")

    @classmethod
    def select(table, connection, filter):
        if connection.canExecuteUnsafe():
            return connection.getDatabase()._getCache_().select(table, connection, filter)
        else:
            raise Exception("Database is locked")

# RowSelection's selections are immutable
class RowSelection:
    def __init__(self, connection, table, rows, filter = None):
        self._connection_ = connection
        self._table_ = table

        # Rows is a dict; {Key: rowID, Value: TableRow}
        self.rows = rows
        self.filter = filter

    def __iter__(self):
        return iter(self.getRows().values())

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
        if self._table_.P_checkLock(self._connection_):
            for row in self.rows.values():
                row.setValue(columnKey, newValue)
        else:
            raise Exception("Database is locked")

    def getRow(self, rowID):
        # Get a single row from the selection set by id
        # No need to mak a duplicate of the returned row; The row objects are thread safe
        return self.rows.get(rowID, None)

    def getRows(self):
        #TODO: raise an exception if self.rows is None
        return self.rows.copy()

    def deleteRows(self):
        # TODO: While this function is running it must have exclusive access to self.rows and self.rowIDs
        for rowID in self.rows.keys():
            self._table_.deleteRow(self._table_, self._connection_, rowID)
        oldRows = self.rows
        self.rows = None
        return oldRows

class Database:
    def __init__(self, dbPath=":memory:"):
        # Data storage
        self.path = dbPath
        self.connections = {}
        self.cache = DatabaseCacheManager()
        self._lock_ = None

        global dbIndex
        self._index_ = dbIndex
        dbIndex += 1

    def _getCache_(self):
        return self.cache

    def _setTransactionLock_(self, lock):
        if self._lock_ is None:
            sqldeb.debug("Setting lock: %s" % lock)
            self._lock_ = lock
            self._getCache_()._beginTransaction_(lock)
            return True
        return False

    def _releaseTransactionLock_(self, lock):
        if self._hasLock_(lock):
            try:
                self._getCache_()._writeCache_(lock)
            except Exception as e:
                self._getCache_()._endTransaction_(lock, True)
                sqldeb.exception(e)
            else:
                self._getCache_()._endTransaction_(lock, False)
            sqldeb.debug("Releasing lock: %s" % lock)
            self._lock_ = None

    def _hasLock_(self, lock):
        locked = lock is not None and self._lock_ is lock
        sqldeb.debug("Checking lock: %s = %s" % (lock, locked))
        return locked

    def _isLocked_(self):
        sqldeb.debug("Is locked? %s" % self._lock_)
        return self._lock_ is not None

    def _abortTransaction_(self, lock):
        if self._hasLock_(lock):
            sqldeb.debug("Aborting transaction: %s" % lock)
            self._getCache_()._endTransaction_(lock, True)

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

    def initTable(self, table, connection):
        result = self._getCache_()._writeTable_(table, connection)
        table.onInit(table, connection)
        return result

class DatabaseConnection:
    def __init__(self, database, connectionName):
        self.connection = None
        self.database = database
        self.name = connectionName

        self._closed_ = False

    def _assertDBConected_(self, connectionState, errorMessage):
        if self._closed_:
            sqlog.error("DatabaseConnection[\"%s\"]: Can't reopen a closed connection!!" % self.getName())
            return not connectionState

        if((self.connection is None) == (not connectionState)):
            return True
        else:
            sqlog.error(errorMessage)
            return False

    def _writeSchema_(self):
        sqlog.debug("STUB: Writing schema to DB...")
        #TODO: This is where the database version will be compared to the schema version to determine they are compatable
        return True

    def isConnected(self):
        return self._assertDBConected_(True, "")

    def canExecuteSafe(self):
        return self.canExecuteUnsafe() or not self.database._isLocked_()

    def canExecuteUnsafe(self):
        return self.database._hasLock_(self)

    def getDatabase(self):
        return self.database

    def getName(self):
        return self.name

    def connect(self, enableForeignConstraint=True):
        #TODO: Change this from an error message to an exceptioon
        if (self._assertDBConected_(False, errorMessage="Database is already connected")):
            sqlog.debug("DatabaseConnection[\"%s\"]: Opening connection to DB %s; Path: \"%s\"; Foreign Key Enforcement: %s" % (self.getName(), self.getDatabase()._index_, self.database.getDBPath(), enableForeignConstraint))
            self.connection = sql.connect(self.database.getDBPath()) #TODO: This is incompatible with multiple connections to ":memory:"
            self.connection.isolation_level = None # Disable the builtin transaction system for the sqlite3 module
            if(self._writeSchema_()):
                self.connection.row_factory = sql.Row # test
                # TODO: Verify that this code will properly handle rolling back in the event of an error
                if(enableForeignConstraint):
                    self.execute("PRAGMA foreign_keys = ON;")
                else:
                    self.execute("PRAGMA foreign_keys = OFF;")
            else:
                sqlog.error("Database File schema is incompatible with provided schema")
                # Now we disconnect to prevent the possibility of db corruption
                self.disconnect(False) # Do not commit; We want to leave the db untouched

    def disconnect(self, commit=True):
        if (self._assertDBConected_(True, errorMessage="Database is not connected")):
            #if(commit):
            #    self.connection.commit()
            self.connection.close()
            self.connection = None
            self._closed_ = True

    def beginTransaction(self, transCommitExceptionCallback=None):
        if (self._assertDBConected_(True, errorMessage="Database is not connected")):
            sqlog.debug("Begining transaction")
            if self.database._setTransactionLock_(self):
                #self.database._setErrorCallback_(transCommitExceptionCallback)
                pass
            else:
                raise Exception("Failed to lock the database")

    def endTransaction(self):
        if (self._assertDBConected_(True, errorMessage="Database is not connected")):
            sqlog.debug("Ending transaction")
            self.database._releaseTransactionLock_(self)

    def abortTransaction(self):
        if (self._assertDBConected_(True, errorMessage="Database is not connected")):
            sqlog.debug("Aborting transaction")
            self.database._abortTransaction_(self)

    def execute(self, query):
        # Note: We intentionally don't check the database lock here
        # Note: This function is not responsible for rolling back changes if there is an error
        if (self._assertDBConected_(True, errorMessage="Database is not connected")):
            try:
                sqlog.debug("DatabaseConnection[\"%s\"] Performing Query: %s" % (self.getName(), query))
                cur = self.connection.execute(query)
                return cur.fetchall()
            except Exception as e:
                sqlog.exception(e)
                raise # We rethrow the exception so that the logic that triggered the error can handle the error

        sqlog.warning("Failed to execute query: %s" % query)
        return None

class DatabaseCacheManager:
    # The cache implements a lazy fill pattern
    # We only add a row to the cache when it is first used

    def __init__(self):

        # {Key: cacheEntryID, Value: cacheData}
        self.cache = {}
        self.entryIndexCounter = 0 #TODO: Continue here

        # {Key: cacheEntryID, Value: (rowID, table)}
        self.cacheMap = {}

        # {Key: cacheEntryID, Value: {Key: columnKey, Value: newValue}}
        self.changes = {}

        # [cacheEntryID]
        self.deleted = set()

        # {Key: cacheEntryID, Value: cacheData}
        #TODO: Implement the logic around this
        self.created = {}

        # This controls whether to delete/unallocate/garbage collect the cached rows after writing to the DB
        self._clearCacheOnWrite_ = False # Having this be true ensures that the cache will always reflect the database

        self._inTransaction_ = False

    def _isDirty_(self):
        #print("%s, %s, %s, %s" % (len(self.created) > 0, len(self.deleted) > 0, len(self.changes) > 0,
        #                      len(self.created) > 0 or len(self.deleted) > 0 or len(self.changes) > 0
        #                      ))
        return len(self.created) > 0 or len(self.deleted) > 0 or len(self.changes) > 0

    def _cacheRow_(self, sqlRow, table):
        # Note: The implementation of this function intentionally does
        # not check for duplicate entries in the cache or the cache mapping

        idColumn = table.getIDColumn(table)
        id = sqlRow[idColumn.name]

        # Update the internal counter
        self.entryIndexCounter += 1

        # Create a cache to sql mapping
        self.cacheMap[self.entryIndexCounter] = (id, table)

        # Actually cache the data
        self.cache[self.entryIndexCounter] = sqlRowToDict(sqlRow, table)

        cadeb.debug("Caching row: %s, %s, %s, %s" % (sqlRow, table, self.entryIndexCounter, id))

        # Return the cache id of the newly cached data
        return self.entryIndexCounter

    # Alias: getCacheForID
    def _initRowDataCache_(self, cacheID):
        if cacheID in self.cache:
            return RowDataCache(cacheID, self)
        else:
            cadeb.warning("No cache entry with id %s" % cacheID)
        return None

    # Alias: cacheToTableRow
    def _initRow_(self, table, rowData):
        rowClass = table.getRowClass(table, rowData)
        return rowClass(rowData, table)

    def _parseRows_(self, rows, table):
        # This function is responsible for converting sqlite3 Row objects into SQLIB TableRow objects
        # And caching any that aren't in the DB

        #Note: The implementation of this function causes it to ignore all changes
        # made to the DB externally for any rows already in the cache
        # This function intentionally ignores whether the row has been deleted

        newRows = []
        idColumn = table.getIDColumn(table)
        for row in rows:
            id = row[idColumn.name]
            cacheRowID = self._lookupRow_(id, table)
            if cacheRowID is None:
                cacheRowID = self._cacheRow_(row, table)

            cacheRowData = self._initRowDataCache_(cacheRowID)
            newRows.append(self._initRow_(table, cacheRowData))
        return newRows

    def _lookupRow_(self, rowID, table):
        #cadeb.debug("Looking up row %s in table %s" % (rowID, table))
        # This function intentionally ignores whether the row has been deleted
        #TODO: Consider creating a reverse mapping table
        #print(self.cacheMap)
        for item in self.cacheMap.items():
            checkRowID = item[1][0]
            checkTable = item[1][1]

            # == to compare value and "is" to match instances

            # This message spams the logging
            #cadeb.debug("Lookup check %s == %s -> %s; %s is %s -> %s" % (rowID, checkRowID, (rowID == checkRowID), checkTable, table, (checkTable is table)))

            # Get a stack trace if rowID is a string
            assert type(rowID) is int

            if int(rowID) == checkRowID and checkTable is table:
                #cadeb.debug("Match found for row %s in table %s" % (rowID, table))
                return item[0] # Return the cacheID

        #cadeb.debug("No match found for row %s in table %s" % (rowID, table))
        return None

    def _getCacheForID_(self, cacheID):
        return self.cache.get(cacheID, None)

    def _writeCache_(self, connection, clearCache = True):
        if connection.canExecuteUnsafe():
            #print("Writing Cache")
            # {Key: Table, Value: (deletedRows, changedRows)}
            pendingChanges = {}

            # Generate the list of changes
            for cacheMapItem in self.cacheMap.items():
                table = cacheMapItem[1][1]
                rowCacheID = cacheMapItem[0]
                rowID = cacheMapItem[1][0]

                if pendingChanges.get(table, None) is None:
                    if self._verifyTable_(table, connection):
                        pendingChanges[table] = ([], [])
                    else:
                        cadeb.error("Failed to write table %s schema to database!" % (table.getTableName(table)))
                        pendingChanges[table] = None

                tmp = pendingChanges[table]
                #print(tmp)
                if tmp is not None:
                    deletedRows = tmp[0]  # This is a list of the row id's
                    changedRows = tmp[1]  # This is a list of the rows marked as dirty
                    # This might need to be changed in the future; but right now new rows are commited at the time of creation
                    # so there is no need to have a list of rows to commit
                    # The issue with changing this is how to get a row id since that is handled automatically by sqlite3 through AUTOINCREMENT:

                    if self._RowisDeleted_(rowCacheID):
                        #print("Found Delete row")
                        deletedRows.append(rowID)
                    elif self._RowisDirty_(rowCacheID):
                        #print("Found dirty row")
                        changedRows.append( (rowID, rowCacheID) )

            # Generate the queries and execute them
            for item in pendingChanges.items():
                table = item[0]
                changeData = item[1]
                deletedRows = changeData[0]
                changedRows = changeData[1]

                # Now we construct a single query to do the delete and then the update
                # TODO: Create a single query that can update many rows with differing values

                delQuery = None
                if len(deletedRows) > 0:
                    delQuery = SQLQueryBuilder(EnumSQLQueryAction.DELETE).FROM(table).WHERE_ID_IN(deletedRows)

                updateQueries = []
                for idTuple in changedRows:
                    updateQueries.append(SQLQueryBuilder(EnumSQLQueryAction.UPDATE).TABLE(table).SET(self._RowgetChanged_(idTuple[1])).WHERE_ID_IS(idTuple[0]))

                #TODO: Check the return values of these queries to ensure the cache remains consistent with the real DB
                # First the data updates
                #print(changedRows)

                for rowUpdateQuery in updateQueries:
                    print(str(rowUpdateQuery))
                    connection.execute(str(rowUpdateQuery))

                # Then we demo everything slated for destruction
                if delQuery is not None:
                    print(str(delQuery))
                    connection.execute(str(delQuery))

            # Verify and fix the foreign key relationships
            #TODO: Implement this
        else:
            print("DB Disallowed unsafe executes")

    def _writeTable_(self, table, connection):
        table.P_writeTable_(table, connection)
        return self._verifyTable_(table, connection)

    def _verifyTable_(self, table, connection):
        # TODO: This is where we actively verify the table integrity and existence
        return True # TODO: Implement this

    def _beginTransaction_(self, connection):
        cadeb.debug("Entering transaction mode")
        # TODO: Verify that this code will properly handle rolling back in the event of an error
        connection.execute("BEGIN TRANSACTION")
        self._inTransaction_ = True

    def _endTransaction_(self, connection, rollback = False):
        # TODO: Verify that this code properly handles sql errors
        cadeb.debug("Exiting transaction mode: Rollback = %s" % rollback)
        if rollback:
            connection.execute("ROLLBACK")
            self._rollbackCacheChanges_()
        else:
            connection.execute("COMMIT")
            self._commitCacheChanges_()

        self._inTransaction_ = False

    def _commitCacheChanges_(self):
        # When this is run we can assume that the foreign key relationships in the database are correct
        # so we proceed to apply the changes in the cache to the state

        # Deleted
        for delID in self.deleted:
            cadeb.debug("Removing %s from the cache and mapping" % delID)
            # Our job is to ensure that no trace if the provided id exists anywhere
            # so we don't check to see whether the id has a valid mapping because we don't care
            self.cache.pop(delID)
            self.cacheMap.pop(delID)

        # Created
        # TODO: Implement this

        # Changes
        for changeData in self.changes.items():
            cacheID = changeData[0]
            changeValues = changeData[1]
            rowData = self.cache.get(cacheID, None)
            if rowData is not None:
                # If the row wasn't deleted
                cadeb.debug("Applying %s to row %s" % (changeValues, rowData))
                for change in changeValues.items():
                    key = change[0]
                    value = change[1]
                    rowData[key] = value

        # Having applied the changes to the cache we reset for the next transaction
        self.changes.clear()
        self.deleted.clear()
        self.created.clear()

    def _rollbackCacheChanges_(self):
        self.changes.clear()
        self.deleted.clear()
        self.created.clear()

    def getRow(self, table, connection, rowID):
        cadeb.debug("%s@%s: Getting row: %s" % (connection.getName(), table.getTableName(table), rowID))

        # First get the row from the cache if it exists
        rowCacheID = self._lookupRow_(rowID, table)
        if rowCacheID is None:
            # The row doesn't exist in the cache so we turn to the DB
            query = SQLQueryBuilder(EnumSQLQueryAction.SELECT).COLUMNS(COLUMN_ANY).FROM(table).WHERE_ID_IN([rowID])
            # TODO: Verify that this code will properly handle rolling back in the event of an error
            result = connection.execute(str(query))
            if len(result) < 1:
                # TODO: raise an excpetion or something
                cadeb.debug("%s@%s: No rows returned: %s" % (connection.getName(), table.getTableName(table), rowID))
                return None

            parsedRows = self._parseRows_(result, table)

            # TODO: Write logic to handle when (by some crazy sequence of events) more than one row is returned
            return parsedRows[0]
        else:
            if self._RowisDeleted_(rowCacheID):
                return None
        return self._initRow_(table, self._initRowDataCache_(rowCacheID))

    def getRows(self, table, connection, rowIDs):
        cadeb.debug("%s@%s: Getting rows: %s" % (connection.getName(), table.getTableName(table), rowIDs))

        cacheRows = {}
        missingRows = []
        for id in rowIDs:
            # The value will be None if there is no cache entry for the row
            rowCacheID = self._lookupRow_(id, table)
            if rowCacheID is None:
                missingRows.append(id)
            else:
                if not self._RowisDeleted_(rowCacheID):
                    #print(self.cache)
                    cacheRows[id] = self._initRow_(table, self._initRowDataCache_(rowCacheID))

        if len(missingRows) > 0:
            cadeb.debug("%s@%s: Querying for missing rows: %s" % (connection.getName(), table.getTableName(table), missingRows))
            query = SQLQueryBuilder(EnumSQLQueryAction.SELECT).COLUMNS(COLUMN_ANY).FROM(table).WHERE_ID_IN(missingRows)
            # TODO: Verify that this code will properly handle rolling back in the event of an error
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
        #print("Rows: %s" % cacheRows)
        return RowSelection(connection, table, cacheRows)

    def createRow(self, table, connection, rowData):
        if self._inTransaction_:
            cadeb.debug("%s@%s: Creating row: %s" % (connection.getName(), table.getTableName(table), rowData))
            #TODO: Revisit the idea of a non write-through create
            # TODO: Verify that all the required columns are passed is and raise an exception if any are missing
            keys = rowData.keys()
            values = rowData.values()
            query = SQLQueryBuilder(EnumSQLQueryAction.INSERT).INTO(table).COLUMNS(keys).VALUES(values)
            rows = connection.execute(str(query))
            #print(rows)
            # TODO: Using getRow means that every time we create a row three queries are run rather than the prefered one
            rowID = connection.execute("SELECT last_insert_rowid()")
            #lastID = connection.connection.lastrowid
            #print("Lastid: %s" % rowID[0][0])
            return self.getRow(table, connection, rowID[0][0])
        else:
            cadeb.error("%s@%s: Failed to create row: %s" % (connection.getName(), table.getTableName(table), rowData))

        return None

    def deleteRow(self, table, connection, rowID):
        if self._inTransaction_:
            cadeb.debug("%s@%s: Deleting row: %s" % (connection.getName(), table.getTableName(table), rowID))
            # Delete from the cache
            rowCacheID = self._lookupRow_(rowID, table)
            if rowCacheID is None:
                #print(self.getRow(table, connection, rowID))
                rowCacheID = self._lookupRow_(rowID, table)

            #print(rowCacheID)
            if rowCacheID is not None:
                #print("Found Row")
                self._RowsetDeleted_(rowCacheID, True)
                return True

        cadeb.debug("%s@%s: Failed to delete row: %s" % (connection.getName(), table.getTableName(table), rowID))
        return False

    def select(self, table, connection, filter):
        #TODO: Replace the string based SQL_WhereStatementBuilder with an object/enum based version
        cadeb.debug("%s@%s: Selecting rows: %s" % (connection.getName(), table.getTableName(table), filter))

        #if self._isDirty_() and connection.canExecuteUnsafe():
        #    # Write the cache to the DB to ensure that when we resolve the query the result will be correct
        #    try:
        #        self._writeCache_(connection, False)
        #    except Exception as e:
        #        cadeb.exception(e)
        #        raise e

        # If we successfully wrote the cache to the DB
        if not self._isDirty_() and self._inTransaction_:
            # First we resolve the query against the DB
            # and get the list of row id's to consider
            idCol = table.getIDColumn(table)
            if idCol is not None:
                query = SQLQueryBuilder(EnumSQLQueryAction.SELECT).COLUMNS([ idCol ]).FROM(table).WHERE(filter)
                # TODO: Verify that this code will properly handle rolling back in the event of an error
                rows = connection.execute(str(query))

                idList = []
                for row in rows:
                    idColumn = table.getIDColumn(table)
                    id = row[idColumn.name]
                    idList.append(id)

                return self.getRows(table, connection, idList)

            cadeb.error("%s@%s: ID column was none!" % (connection.getName(), table.getTableName(table)))
        else:
            cadeb.error("%s@%s: Can't perform SELECT; Database cache has uncommitted changes" % (connection.getName(), table.getTableName(table)))
        return None

    def _RowisDeleted_(self, objectID):
        return objectID in self.deleted

    def _RowsetDeleted_(self, objectID, value):
        if value:
            self.deleted.add(objectID)
        else:
            self.deleted.remove(objectID)

    def _RowgetChanged_(self, objectID):
        return self.changes.get(objectID, None)

    def _RowisDirty_(self, objectID):
        return objectID in self.changes

    def _RowisNew_(self, objectID):
        return objectID in self.created

    def _RowgetValue_(self, objectID, columnKey):
        # This function intentionally ignores whether the row has been deleted
        changes = self._RowgetChanged_(objectID)
        if changes is not None:
            value = changes.get(columnKey, null)
            #print(value)
            if type(value) is not _NullValue_:
                return value

        cacheEntry = self.cache.get(objectID, None)
        #print(cacheEntry)
        if cacheEntry is not None:
            value = cacheEntry.get(columnKey, null)
            #print(value)
            if type(value) is not _NullValue_:
                return value

        #print(self.cache)
        cadeb.error("Invalid Key %s for cache id %s; type(%s)" % (columnKey, objectID, type(columnKey)))
        return null

    def _RowsetValue_(self, objectID, columnKey, value):
        # This function intentionally ignores whether the row has been deleted
        if self._inTransaction_ and objectID in self.cache:
            row = self.changes.get(objectID, {})
            oldValue = row.get(columnKey, self.cache.get(objectID, {}).get(columnKey, null))
            if(type(oldValue) is not _NullValue_):
                if columnKey.value.getType().value.verify(value) and columnKey.value.verify(value):
                    #print("Row is dirty")
                    typeSanitized = columnKey.value.getType().value.sanitize(value)
                    row[columnKey] = columnKey.value.sanitize(typeSanitized)
                    self.changes[objectID] = row
                    return oldValue
                else:
                    cadeb.error("Invalid value %s for column %s" % (value, columnKey))
        else:
            cadeb.error("Unable to set value for cache object %s" % objectID)

class RowDataCache:
    def __init__(self, cacheEntryID, cacheManager):
        self._entryID_ = cacheEntryID
        self._cacheManager_ = cacheManager

    def isDirty(self):
        return self._cacheManager_._RowisDirty_(self._entryID_)

    def isDeleted(self):
        return self._cacheManager_._RowisDeleted_(self._entryID_)

    def _setDeleted_(self, isDeleted):
        self._cacheManager_._RowsetDeleted_(self._entryID_)

    def _changed_(self):
        return self._cacheManager_._RowgetChanged_(self._entryID_)

    def isNew(self):
        return self._cacheManager_._RowisNew_(self._entryID_)

    def getValue(self, columnKey):
        return self._cacheManager_._RowgetValue_(self._entryID_, columnKey)

    def setValue(self, columnKey, value):
        return self._cacheManager_._RowsetValue_(self._entryID_, columnKey, value)

class _NullValue_:
    pass
null = _NullValue_()

class EnumSQLQueryAction(Enum):
    SELECT = "SELECT"
    DELETE = "DELETE"
    UPDATE = "UPDATE"
    INSERT = "INSERT INTO"

class SQLQueryBuilder:
    def __init__(self, action):
        self.action = action
        self.table = None # FROM
        self.idList = None # Used for the where statement
        self.filter = None # Takes precedence over the idList
        self.columns = None # Used by select and similar
        self.updates = None # Used by UPDATE
        self.values = None # Used by INSERT

    def VALUES(self, values):
        self.values = values
        return self

    def SET(self, columnDict):
        self.updates = columnDict
        return self

    def COLUMNS(self, columnList):
        self.columns = columnList
        return self

    # This is syntactic sugar
    def TABLE(self, tableKey):
        return self.FROM(tableKey)

    # This is syntactic sugar
    def INTO(self, tableKey):
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
        useVALUES = False

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

        if self.action is EnumSQLQueryAction.INSERT:
            useVALUES = True

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
                        if type(i[1]) is str:
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

        valueStr = None
        if useVALUES:
            valueStr = ", ".join(["\"%s\"" % val if type(val) is str else "%s" % ('null' if val is None else str(val)) for val in self.values])

        if whereStr is None:
            whereStr = ""

        queryStr = None
        if self.action is EnumSQLQueryAction.SELECT:
            queryStr = "%s %s %s %s" % (action, columnStr, fromStr, whereStr)

        if self.action is EnumSQLQueryAction.DELETE:
            queryStr = "%s %s %s" % (action, fromStr, whereStr)

        if self.action is EnumSQLQueryAction.UPDATE:
            queryStr = "%s %s %s %s" % (action, fromStr, columnStr, whereStr)

        if self.action is EnumSQLQueryAction.INSERT:
            queryStr = "%s %s (%s) VALUES (%s)" % (action, fromStr, columnStr, valueStr)

        # INSERT INTO [Table] ({Columns}) VALUES ({Values})
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
