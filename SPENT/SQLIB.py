import sqlite3 as sql
import traceback, sys

def printException(exception):
    desired_trace = traceback.format_exc()
    print(desired_trace)

class test():
    def __init__(self, cursor, data):
        print(cursor)
        print([description[0] for description in cursor.description])
        print(data)
        print(sql.Row(cursor, data))
        print("------")

class TableRow():
    def __init__(self, rowID, table):
        self.table = table
        self.rowID = rowID

    def getRowID(self):
        return self.rowID

    def getColumnByIndex(self, index) -> 'Column':
        pass

    def getColumnByName(self, name):
        pass

    def getColumnCount(self) -> int:
        pass

    # Short for row.getColumnByName(...).setValue(...)
    def setValue(self, columnKey: 'Column', value):
        pass

    # Short for row.getColumnByName(...).getValue()
    def getValue(self, columnKey):
        pass

class Column:
    def __init__(self, index, name):
        self.index = index
        self.name = name

    def getIndex(self):
        return self.index

    def getName(self):
        return self.name

class TableColumn(Column):
    def __init__(self, table, index, properties):
        #FIXME: Never assume a dictionary has a value for our key without checking
        print("Initializing Column: %s.%s" % (table.getName(), properties["name"]))
        super().__init__(index, properties["name"])
        self.table = table

        # TODO: Create an object/primitive based way of storing the table def rather then strings and dicts
        self.properties = properties

class VirtualColumn(Column):
    pass

class Table:
    def __init__(self, name, tableSchema, virtualColumns=[]):
        print("Initializing Table: %s" % name)
        self.name = name
        self.constraints = []
        self.columns = self._parseSchema_(tableSchema)
        #TODO: Handle virtual columns

    def _parseSchema_(self, tableSchema):
        columns = []
        for index in range(len(tableSchema)):
            # TODO: Parse the type value in the colum def and create a IntColumn or StringColumn, etc.
            if tableSchema[index].get("isConstraint", False) is False:
                colObj = TableColumn(self, index, tableSchema[index])
                columns.append(colObj)
            else:
                self.constraints.append(tableSchema[index])
        return columns

    def _parseVirtualColumns_(self):
        pass

    def _writeTable_(self, connection):
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

    def getColumns(self):
        pass

    def getName(self):
        return self.name

class Database:
    def __init__(self, schema, dbPath=":memory:"):
        # Data storage
        self.path = dbPath
        self.connections = {}
        self.schema = schema
        self.cache = DatabaseCacheManager(self.schema)

        # Runtime State
        self._schemaIsWritten_ = False

    def _getCache_(self):
        pass

    def getConnection(self, connectionName=""):
        # TODO: Check for duplicate connections and delete dead ones
        conn = DatabaseConnection(self, connectionName)
        self.connections[connectionName] = conn
        return conn

    def getDBPath(self):
        return self.path

    def getSchema(self):
        return self.schema

class DatabaseSchema:
    def __init__(self, version,  tableDefs):
        self.tables = self._parseTables_(tableDefs)
        self.version = version

        #TODO: This variable must be removed; it breaks the ability to reuse a schema object with multiple database instances
        self._database_ = None

    def _parseTables_(self, tableDefs):
        tables = {}
        for t in tableDefs:
            name = t.get("table", None)
            columns = t.get("columns", None)
            virtualColumns = t.get("virtualColumns", None)
            #TODO: constraints = t.get("constraints", None)

            if name is not None and (columns is not None or virtualColumns is not None):
                tables[name] = Table(name, columns, virtualColumns)
        return tables

    def getTables(self):
        return self.tables.values()

    def getTable(self, tableName):
        table = self.tables.get(tableName, None)
        if table is None:
            print("No such table %s" % tableName)
        return table

    def getSchemaVersion(self):
        return self.version

class DatabaseConnection:
    def __init__(self, database, connectionName):
        self.connection = None
        self.database = database
        self.name = connectionName

    def _assertDBConected_(self, connectionState, errorMessage):
        if((self.connection is None) == (not connectionState)):
            return True
        else:
            print("Error: %s" % errorMessage)
            return False

    def _writeSchema_(self):
        # TODO: actually verify the integrity of the data we are working with
        # TODO: We do noting with the version number yet; Use It!
        if not self.database._schemaIsWritten_:
            try:
                for table in self.database.getSchema().getTables():
                    table._writeTable_(self)
            except Exception as e:
                printException(e)
                return False

        # TODO: Return false if there is any issue or error at all in writing the table schema
        self.database._schemaIsWritten_ = True
        return True

    def getName(self):
        return self.name

    def connect(self):
        if (self._assertDBConected_(False, "Database is already connected")):
            print("Debug: DatabaseConnection[\"%s\"]: Opening connection to DB; Path: \"%s\"" % (self.getName(), self.database.getDBPath()))
            self.connection = sql.connect(self.database.getDBPath())
            if(self._writeSchema_()):
                self.connection.row_factory = sql.Row # test
            else:
                print("Error: Database File schema is incompatible with provided schema")
                # Now we disconnect to prevent the possibility of db corruption
                self.disconnect(False) # Do not commit; We want to leave the db untouched
        else:
            return

    def disconnect(self, commit=True):
        if (self._assertDBConected_(True, "Database is not connected")):
            if(commit):
                self.connection.commit()
            self.connection.close()
            self.connection = None

    def commit(self):
        if (self._assertDBConected_(True, "Database is not connected")):
            self.commit()

    def execute(self, query):
        if (self._assertDBConected_(True, "Database is not connected")):
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

    def getRow(self, tableKey, rowID):
        #self.database._getCache_().get()
        pass

    def getRows(self, tableKey, rowIDs):
        pass

    def createRow(self, tableKey, rowData):
        pass

    def deleteRow(self, tableKey, rowID):
        pass

    def deleteRows(self, tableKey, rowIDs):
        pass

    def select(self, tableKey, filter):
        pass

class RowSelection:
    def getValues(self):
        pass

    def setValues(self, columnKey, newValue):
        pass

    #TODO: This must return a copy of the list of rows
    def getRows(self):
        pass

    def deleteRows(self):
        pass

    # This re-runs the query used to get the selection
    # and updates the selections list of rows
    def refresh(self):
        pass

class DatabaseCacheManager:
    def __init__(self, schema):
        self.schema = schema