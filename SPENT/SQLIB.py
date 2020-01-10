import sqlite3 as sql
import traceback, sys

from sphinx.addnodes import desc

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

    def getColumnByIndex(self) -> 'Column':
        pass

    def getColumnByName(self):
        pass

    def getColumnCount(self) -> int:
        pass

class Column:
    def __init__(self, index, name):
        self.index = index
        self.name = name

    def getIndex(self):
        return self.index

    def getName(self):
        return self.name

    def getValue(self, row):
        pass

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

    def getRowByID(self):
        pass

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

        # Runtime State
        self._schemaIsWritten_ = False

    def getConnection(self, connectionName=""):
        # TODO: Check for duplicate connections
        conn = DatabaseConnection(self, connectionName)
        self.connections[connectionName] = conn
        return conn

    def getDBPath(self):
        return self.path

    def getSchema(self):
        return self.schema

class DatabaseSchema:
    def __init__(self, version,  tableDefs):
        self.tables = tableDefs
        self.version = version

    def getTables(self):
        return self.tables

    def getSchemaVersion(self):
        return self.version

class DatabaseConnection:
    def __init__(self, database, connectionName):
        self.connection = None
        self.database = database
        self.name = connectionName

    def _dbIsConnected_(self, connectionState, errorMessage):
        if((self.connection is None) == connectionState):
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
        if (self._dbIsConnected_(True, "Database is already connected")):
            print("Debug: DatabaseConnection[\"%s\"]: Opening connection to DB; Path: \"%s\"" % (self.getName(), self.database.getDBPath()))
            self.connection = sql.connect(self.database.getDBPath())
            if(self._writeSchema_()):
                self.connection.row_factory = sql.Row # test
            else:
                print("Error: Database File schema is incompatible with provided schema")
                # Now we disconnect to prevent the possibility of db corruption
                self.disconnect(False) # Do not commit; We want to leave the db untouched

    def disconnect(self, commit=True):
        if (self._dbIsConnected_(False, "Database is not connected")):
            if(commit):
                self.connection.commit()
            self.connection.close()
            self.connection = None

    def commit(self):
        if (self._dbIsConnected_(False, "Database is not connected")):
            self.commit()

    def execute(self, query):
        if (self._dbIsConnected_(False, "Database is not connected")):
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

class RowDataCache:
    pass

class TableRowDataCache(RowDataCache):
    pass