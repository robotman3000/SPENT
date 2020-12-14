/**
 * Warn user if the given model is a type of an inherited model that is being
 * defined without overwriting `Model.types()` because the user will not be
 * able to use the type mapping feature in this case.
 */
VuexORM.Database.prototype.checkModelTypeMappingCapability = function (model) {
    // We'll not be logging any warning if it's on a production environment,
    // so let's return here if it is.
    /* istanbul ignore next */
    console.log("Patched checkModelTypeMappingCapability");
    //if (process.env.NODE_ENV === 'production') {
    //    return;
    //}
    // If the model doesn't have `baseEntity` property set, we'll assume it is
    // not an inherited model so we can stop here.
    if (!model.baseEntity) {
        return;
    }
    // Now it seems like the model is indeed an inherited model. Let's check if
    // it has `types()` method declared, or we'll warn the user that it's not
    // possible to use type mapping feature.
    var baseModel = this.model(model.baseEntity);
    if (baseModel && baseModel.types === VuexORM.Model.types) {
        console.warn("[Vuex ORM] Model `" + model.name + "` extends `" + baseModel.name + "` which doesn't " +
            'overwrite Model.types(). You will not be able to use type mapping.');
    }
};
VuexORM.Relation.prototype.getKeys = function (collection, key) {
    console.log("Patched Relation.getKeys");
    return collection.reduce(function (models, model) {
        if (Object.prototype.toString.call( key ) === '[object Array]'){
            // TODO: For now we assume an array with two values
            if (model[key[0]] === null || model[key[0]] === undefined || model[key[1]] === null || model[key[1]] === undefined) {
                return models;
            }
            models.push(JSON.stringify([model[key[0]], model[key[1]]]));
            return models;
        }

        if (model[key] === null || model[key] === undefined) {
            return models;
        }
        models.push(model[key]);
        return models;
    }, []);
};
VuexORM.HasOne.prototype.match = function (collection, relations, name) {
    console.log("Patched HasOne.match");
    var _this = this;
    var dictionary = this.buildDictionary(relations);
    collection.forEach(function (model) {
        var id = model[_this.localKey];
        if (Object.prototype.toString.call( _this.localKey ) === '[object Array]'){
            id = JSON.stringify([model[_this.localKey[0]], model[_this.localKey[1]]]);
        }
        var relation = dictionary[id];
        model[name] = relation || null;
    });
};
//######################

var formatter = null;

var supportsES6 = function() {
  try {
    new Function("(a = 0) => a");
    return true;
  }
  catch (err) {
    return false;
  }
}();

//TODO: Make a common base object for api and properties and enum
var PropertyRequestManager = function(){
    this.requestPackets = [];

    this.selectRecords = function(dataTypeName, fuzzyData, rules){
        //TODO: this should check that the function args are valid
        var packet = this._createRequest_("get", dataTypeName, fuzzyData, null, null)
        this._queueRequestPacket_(packet)
    };

    this.updateRecords = function(dataTypeName, updatedData){
        //TODO: this should check that the function args are valid
        var packet = this._createRequest_("set", dataTypeName, updatedData, null, null)
        this._queueRequestPacket_(packet)
    };

    this.sendRequest = function(){
        var self = this;
        var promise = this._apiRequest_(this.requestPackets);
        this.requestPackets = []
        return promise;
    };

    this.handleAPIError = function(data){alert("error!")};

    this._apiRequest_ = function(requestObj){
        var self = this;
        return $.ajax({
            url: '/property/query',
            type: "POST",
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            data: JSON.stringify(requestObj),
            success: function(data) {
                if(!data.successful){
                    alert("API Error: " + response.message);
                }
            },
            error: function(data) {
                alert("Server Error!! " + JSON.stringify(data));
            }
        });
    };

    this._createRequest_ = function(action, type, data, columns, rules){
        //TODO: Verify the input data and sanitize it
        var request = {
            action: action,
            type: type
        }

        var properties = [{name: "data", value: data, def: {}}]
        properties.forEach(function(item, index){
            if(item.value != undefined && item.value != null){
               request[item.name] = item.value;
                if(item.value.length < 1){
                    request[item.name] = null;
                }
            } /*else {
                request[item.name] = item.def;
            }*/
        });

        //request.debugTrace = new Error().stack;
        return request
    };

    this._queueRequestPacket_ = function(requestObj){
        this.requestPackets.push(requestObj);
    };

};
var propertyManager = new PropertyRequestManager();

var APIRequestManager = function(){
    this.requestPackets = [];

    this.selectRecords = function(dataTypeName, fuzzyData, rules, filter){
        //TODO: this should check that the function args are valid
        var packet = this._createRequest_("get", dataTypeName, fuzzyData, null, rules, filter)
        this._queueRequestPacket_(packet)
    };

    this.updateRecords = function(dataTypeName, updatedData){
        //TODO: this should check that the function args are valid
        var packet = this._createRequest_("update", dataTypeName, updatedData, null, null)
        this._queueRequestPacket_(packet)
    };

    this.deleteRecords = function(dataTypeName, fuzzyData /*, rules*/){
        //TODO: this should check that the function args are valid
        var packet = this._createRequest_("delete", dataTypeName, fuzzyData, null, null)
        this._queueRequestPacket_(packet)
    };

    this.createRecords = function(dataTypeName, createdData){
        //TODO: this should check that the function args are valid
        var packet = this._createRequest_("create", dataTypeName, createdData, null, null)
        this._queueRequestPacket_(packet)
    };

    this.sendRequest = function(){
        var self = this;
        var promise = this._apiRequest_(this.requestPackets)
        this.requestPackets = []
        return promise;
    };

    this._apiRequest_ = function(requestObj){
        var self = this;
        return $.ajax({
            url: '/database/apiRequest',
            type: "POST",
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            data: JSON.stringify(requestObj),
            success: function(data) {
                if(!data.successful){
                    alert("API Error: " + response.message);
                }
            },
            error: function(data) {
                alert("Server Error!! " + JSON.stringify(data));
            }
        });
    };

    this._createRequest_ = function(action, type, data, columns, rules, filter){
        //TODO: Verify the input data and sanitize it
        var request = {
            action: action,
            type: type
        }

        //TODO: remove "filter" once "rules" is properly implemented
        var properties = [{name: "data", value: data, def: {}}, {name: "columns", value: columns, def: []}, {name: "rules", value: rules, def: {}}, {name: "filter", value: filter, def: {}}]
        properties.forEach(function(item, index){
            if(item.value != undefined && item.value != null){
               request[item.name] = item.value;
                if(item.value.length < 1){
                    request[item.name] = null;
                }
            }
        });

        //request.debugTrace = new Error().stack;
        return request
    };

    this._queueRequestPacket_ = function(requestObj){
        this.requestPackets.push(requestObj);
    };

};
var requestManager = new APIRequestManager();

var EnumRequestManager = function(){
    this.requestPackets = [];

    this.requestEnum = function(dataTypeName){
        //TODO: this should check that the function args are valid
        var packet = this._createRequest_(dataTypeName)
        this._queueRequestPacket_(packet)
    };

    this.sendRequest = function(){
        var self = this;
        var req = this._apiRequest_(this.requestPackets)
        this.requestPackets = []
        return req;
    };

    this._apiRequest_ = function(requestObj, suc, err){
        var self = this;
        return $.ajax({
            url: '/enum/query',
            type: "POST",
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            data: JSON.stringify(requestObj),
            success: function(data) {
                if(!data.successful){
                    alert("API Error: " + response.message);
                }
            },
            error: function(data) {
                alert("Server Error!! " + JSON.stringify(data));
            }
        });
    };

    this._createRequest_ = function(enumName){
        //TODO: Verify the input data and sanitize it
        var request = {
            action: "get",
            type: "enum",
            enum: enumName,
        }
        return request
    };

    this._queueRequestPacket_ = function(requestObj){
        this.requestPackets.push(requestObj);
    };
};
var enumManager = new EnumRequestManager();

function getOrDefault(object, property, def, allowNull){
    if (object){
        if(object[property] === null && allowNull){
            return null;
        }
        return (object[property] !== undefined ? object[property] : def);
    }
	return def;
}

function getTransferDirection(rowData, selectedAccount){
    // True = Money Coming in; I.E. a positive value
    // False = Money Going out; I.E. a negative value
    var ID = selectedAccount;
    switch(rowData.Type){
        case 0:
            return (rowData.DestBucket == ID);
            break;
        case 1:
            return true;
            break;
        case 2:
            return false;
            break;
    }
    return null;
}

// Vuex ORM Models
//alert(supportsES6);
function apiUpdate(data, entity){
    data["ID"] = data["id"];
    requestManager.updateRecords(entity, [data]);
};
function apiCreate(data, entity){
    data["ID"] = data["id"];
    requestManager.createRecords(entity, [data]);
};
function apiDelete(data, entity){
    data["ID"] = data["id"];
    requestManager.deleteRecords(entity, [data]);
};
function apiCommit(){
    dbStore.dispatch("sendDBRequest");
};
class Transaction extends VuexORM.Model {};
//class Payee extends VuexORM.Model {};
//class Transfer extends VuexORM.Model {};
class Bucket extends VuexORM.Model {};
class Account extends Bucket {};
class Property extends VuexORM.Model {};

Property.entity = 'property';
Property.primaryKey = ['recordID', 'name'];
Property.fields = function() {
    return {
        name: this.string(null),
        recordID: this.number(null),
        value: this.attr(null),
    }
};

Transaction.entity = 'transaction';
Transaction.primaryKey = 'id';
Transaction.prototype.apiCreate = apiCreate;
Transaction.prototype.apiUpdate = apiUpdate;
Transaction.prototype.apiDelete = apiDelete;
Transaction.prototype.apiCommit = apiCommit;
Transaction.fields = function() {
    return {
        id: this.number(null),
        Status: this.number(0),
        TransDate: this.string("1970-01-01"),
        PostDate: this.string("1970-01-01"),
        Amount: this.number(0),
        SourceBucket: this.number(0),
        DestBucket: this.number(0),
        SourceBucketObj: this.belongsTo('bucket', 'SourceBucket'),
        DestBucketObj: this.belongsTo('bucket', 'DestBucket'),
        Memo: this.string(null),
        Payee: this.string(null),
        Type: this.number(null),
    }
};

Bucket.entity = 'bucket';
Bucket.primaryKey = 'id';
Bucket.typeKey = 'Type';
Bucket.prototype.apiCreate = apiCreate;
Bucket.prototype.apiUpdate = apiUpdate;
Bucket.prototype.apiDelete = apiDelete;
Bucket.prototype.apiCommit = apiCommit;
Bucket.fields = function() {
    return {
      id: this.number(null),
      Name: this.string(null),
      Parent: this.number(-1),
      Ancestor: this.number(-1),
      Type: this.number(0),
      availableBalance: this.hasOne(Property, '$id', ['id', 'availableBalanceKey']),
      availableBalanceKey: this.string("SPENT.bucket.availableBalance"),
      availableTreeBalance: this.hasOne(Property, '$id', ['id', 'availableTreeBalanceKey']),
      availableTreeBalanceKey: this.string("SPENT.bucket.availableTreeBalance"),
      postedBalance: this.hasOne(Property, '$id', ['id', 'postedBalanceKey']),
      postedBalanceKey: this.string("SPENT.bucket.postedBalance"),
      postedTreeBalance: this.hasOne(Property, '$id', ['id', 'postedTreeBalanceKey']),
      postedTreeBalanceKey: this.string("SPENT.bucket.postedTreeBalance"),
      //transactions: this.has
    }
};
Bucket.types = function(){
    return {
      0: Bucket,
      1: Account,
    }
}

Account.baseEntity = 'bucket';
Account.entity = 'account';
Account.prototype.apiCreate = apiCreate;
Account.prototype.apiUpdate = apiUpdate;
Account.prototype.apiDelete = apiDelete;
Account.prototype.apiCommit = apiCommit;
Account.fields = function() {
    return {
        ...Bucket.fields(),
    }
}

Vue.use(Vuex);
Vue.use(Inkline);

// Create a new instance of Database.
const database = new VuexORM.Database()

// Register Models to Database.
database.register(Bucket)
database.register(Account)
database.register(Transaction)
database.register(Property)


function parseServerResponse(context, responseRecord){
    var type = responseRecord.type;
    var action = responseRecord.action;
    var data = responseRecord.data;
    var enumName = getOrDefault(responseRecord, "enum", null);

    var functionNameMap = {
        "account": "mutateAccounts",
        "bucket": "mutateBuckets",
        "transaction": "mutateTransactions",
        "property": "mutateProperties",
        "enum": "mutateEnums",
    };
    var handlerName = getOrDefault(functionNameMap, type, null)
    if(handlerName){
        data.forEach(function(item){
            if(item['ID']){
                item['id'] = item['ID']
            }
        });
        var payload = {action: action, data: data};

        if(enumName){
            payload["enumName"] = enumName
        }
        context.commit(handlerName, payload)
    } else {
        alert("Error: Cannot commit record: Unknown data type \"" + type + "\"");
    }
};
// Create Vuex Store and register database through Vuex ORM.
const dbStore = new Vuex.Store({
    plugins: [VuexORM.install(database)],
    strict: true,
    state: {
        enumList: [],
        enumStore: {},
    },
    getters: {
        getEnumNameByValue: (state) => (value, enumKey) => {
            var enumID = state.enumList.indexOf(enumKey);
            if(enumID != -1){
                var result = getOrDefault(getOrDefault(state.enumStore[enumID], value, null), "name", null);
                return result;
            }
            return "Invalid Enum";
        },
    },
    actions: {
        sendDBRequest(context){
            console.log("running sendDBRequest");
            return requestManager.sendRequest().done(function(response){
                var records = response.records;
                records.forEach((item) => parseServerResponse(context, item))
            })
        },
        sendPropRequest(context){
            console.log("running sendPropRequest");
            return propertyManager.sendRequest().done(function(response){
                var records = response.records;
                records.forEach((item) => parseServerResponse(context, item))
            })
        },
        sendEnumRequest(context){
            console.log("running sendEnumRequest");
            return enumManager.sendRequest().done(function(response){
                var records = response.records;
                records.forEach((item) => parseServerResponse(context, item))
            })
        },
        fetchAllBucketBalances(context){
            Bucket.all().forEach(function(item){
                propertyManager.selectRecords("property",
                [{"name": "SPENT.bucket.availableTreeBalance", "recordID": item.id},
                {"name": "SPENT.bucket.postedTreeBalance", "recordID": item.id},
                {"name": "SPENT.bucket.availableBalance", "recordID": item.id},
                {"name": "SPENT.bucket.postedBalance", "recordID": item.id}]);
            });
            dbStore.dispatch("sendPropRequest");
        },
    },
    mutations: {
        mutateTransactions: function(state, data){
            var action = data.action;
            if(action == "get" || action == "create"){
                Transaction.create({data: data.data});
            } else if (action == "update"){
                Transaction.insert({data: data.data});
            } else {
                alert("Error: Cannot commit transaction mutation: Unknown action \"" + action + "\"");
            }
        },
        mutateAccounts: function(state, data){
            var action = data.action;
            if(action == "get" || action == "create"){
                Account.create({data: data.data});
            } else if (action == "update"){
                Account.insert({data: data.data});
            } else {
                alert("Error: Cannot commit account mutation: Unknown action \"" + action + "\"");
            }
        },
        mutateBuckets: function(state, data){
            var action = data.action;
            if(action == "get" || action == "create"){
                Bucket.create({data: data.data});
            } else if (action == "update"){
                Bucket.insert({data: data.data});
            } else {
                alert("Error: Cannot commit account mutation: Unknown action \"" + action + "\"");
            }
        },
        mutateProperties: function(state, data){
            console.log("running setPropertyValues");
            var action = data.action;
            if(action == "get"){
                Property.insert({data: data.data});
            } else {
                alert("Error: Cannot commit property mutation: Unknown action \"" + action + "\"");
            }
        },
        mutateEnums: function(state, params){
            console.log("running setEnumValues");

            var enumID = state.enumList.indexOf(params.enumName);
            if(enumID == -1){
                enumID = state.enumList.push(params.enumName) - 1;
            }
            console.log("setting enum: " + params.enumName + " Value: " + params.data + " Index: " + enumID);
            Vue.set(state.enumStore, enumID, params.data);
        },
    },
})

Vue.component("tree-view", {
    template: `
        <ul class="tree-root _padding-left-1">
            <tree-item v-for="(child, index) in parentChildMap[-1]" :key="index" :node="child" :parentChildMap="parentChildMap" @node-click="forwardClick" :currentnode="selectednode"></tree-item>
        </ul>
    `,
    props: {
        nodes: Array,
        selectednode: Number,
    },
    methods: {
        forwardClick: function(id){
            console.log("Tree Node Forward Click Root: " + id);
            this.$emit("node-click", id);
        },
    },
    computed: {
        parentChildMap: function(){
            var parentChildList = {};
            this.nodes.forEach(function(account){
                var parentID = getOrDefault(account, "Parent", null);

                var siblingList = getOrDefault(parentChildList, parentID, new Set());
                siblingList.add(account);
                parentChildList[parentID] = siblingList;
            });
            return parentChildList;
        },
    },
});
Vue.component("tree-item", {
    template: `
        <li style="list-style-type: none;" :class="{bold: isFolder}" class="_margin-bottom-0">
            <div style="display: inline-block; width: 100%; padding-bottom: 8px;" class="tree-item" :class="{nodeSelected: isSelected}"
            @click.self="select">
            <span v-if="isFolder" @click.self="toggle">[{{ isOpen ? '-' : '+' }}]</span>
            {{ node.Name }}
            <i-badge :variant="isNegative ? 'danger' : 'light'" class="_float-right" style="min-width: 8em;">{{ node.postedBalance ? format(node.postedBalance.value) : "$-0.00" }}</i-badge>
            </div>
            <ul v-show="isFolder" :class="{nodeClosed: !isOpen}">
                <tree-item v-for="(child, index) in parentChildMap[node.id]" :key="index" :node="child" :parentChildMap="parentChildMap" @node-click="forwardClick" :currentnode="currentnode">></tree-item>
            </ul>
        </li>
    `,
    props: {
        node: Object,
        parentChildMap: Object,
        currentnode: Number,
    },
    data: function() {
        return {
            isOpen: false,
        };
    },
    computed: {
        isFolder: function() {
            return this.parentChildMap[this.node.id] && this.parentChildMap[this.node.id].size > 0;
        },
        isSelected: function(){
            //console.log("Checking isSelected: " + (this.item.id == this.currentnode));
            return this.node.id == this.currentnode;
        },
        isNegative: function(){
            return (this.node.postedBalance ? this.node.postedBalance.value < 0 : false)
        },
    },
    methods: {
        toggle: function() {
            if (this.isFolder) {
                this.isOpen = !this.isOpen;
            }
        },
        select: function(){
            console.log("Tree Node Click: " + this.node.id)
            this.$emit("node-click", this.node.id);
        },
        forwardClick: function(id){
            console.log("Tree Node Forward Click: " + id);
            this.$emit("node-click", id);
        },
        format: (value) => formatter.format(value),
    }
});

Vue.component("enum-table-cell", {
    name: 'enum-table-cell',
    props: ['row', 'column', 'index'],
    template: `<span>{{ cellValue }}</span>`,
    computed: {
        cellValue (){
            let value = this.row[this.column.path];
            let enumKey = this.column.enumName;
            console.log("rendering enum cell " + value + " with " + enumKey);
            return dbStore.getters.getEnumNameByValue(value, enumKey);
        },
    },
});
Vue.component("currency-table-cell", {
    name: 'currency-table-cell',
    props: ['row', 'column', 'index'],
    template: `<span :class="{ '_text-danger': isNegative}">{{ cellValue }}</span>`,
    computed: {
        cellValue (){
            let value = this.row[this.column.path];
            console.log("rendering currency cell " + value + " with " + this.row);
            return formatter.format(value * (this.isNegative ? -1 : 1));
        },
        isNegative (){
            return !getTransferDirection(this.row, this.$root.selectedBucketID);
        },
    },
});
Vue.component("bucket-table-cell", {
    name: 'bucket-table-cell',
    props: ['row', 'column', 'index'],
    template: `<span>{{ cellValue }}</span>`,
    computed: {
        cellValue (){
            console.log("rendering bucket cell with " + this.row);
            var id = -2; //This value will cause the name func to return "Invalid ID"

            var transType = this.row.Type;
            var isDeposit = !this.isNegative;
            if(transType != 0){
                id = (transType == 1 ? this.$vnode.data.attrs.data.DestBucket : this.$vnode.data.attrs.data.SourceBucket);
            } else {
                id = (isDeposit ? this.$vnode.data.attrs.data.SourceBucket : this.$vnode.data.attrs.data.DestBucket);
            }

            return Bucket.query().whereId(id).first().Name;
        },
        isNegative (){
            return !getTransferDirection(this.row, this.$root.selectedBucketID);
        },
    },
});

function doFormSubmit(formName){
    var data = this.parseFormData(this.formSchema, this.formSchema.fields);

    if(getOrDefault(data, "id", null) == null){
        this.formObjectClass.prototype.apiCreate(data, this.formObjectClass.entity);
    } else {
        this.formObjectClass.prototype.apiUpdate(data, this.formObjectClass.entity);
    }
    this.formObjectClass.prototype.apiCommit();
    this.$emit('form-submit', formName);
};
function parseFormData(obj, fields){
    var newObj = {};
    fields.forEach(function(fieldName){
        let value = null;
        if (obj){
            value = getOrDefault(obj, fieldName, undefined, true);
        }
        if(value !== undefined){
            newObj[fieldName] = value.value;
        } else {
            console.log("[SPENT] Failed to assign value to object \'" + key + "\'");
        }
    });
    return newObj;
};

Vue.component("transaction-form", {
    name: 'transaction-form',
    props: ['formSchema'],
    template: `
        <i-form v-model="formSchema" @submit="doFormSubmit(\'transaction\')">
            <i-form-group>
                <i-form-label>Status</i-form-label>
                <i-select :schema="formSchema.Status" placeholder="Choose a status">
                    <i-select-option value="0" label="Void" />
                    <i-select-option value="1" label="Uninitiated" />
                    <i-select-option value="2" label="Submitted" />
                    <i-select-option value="3" label="Post Pending" />
                    <i-select-option value="4" label="Complete" />
                    <i-select-option value="5" label="Reconciled" />
                </i-select>
            </i-form-group>

            <i-form-group>
                <i-form-label>Date</i-form-label>
                <i-input :schema="formSchema.TransDate" placeholder="Enter a date" />
            </i-form-group>

            <i-form-group>
                <i-form-label>Post Date</i-form-label>
                <i-input :schema="formSchema.PostDate" placeholder="Enter a date" />
            </i-form-group>

            <i-form-group>
                <i-form-label>Amount</i-form-label>
                <i-input :schema="formSchema.Amount" placeholder="Enter an amount" />
            </i-form-group>

            <i-form-group>
                <i-form-label>Source Bucket</i-form-label>
                <i-input :schema="formSchema.SourceBucket" placeholder="source bucket" />
                <!--i-select :schema="formSchema.SourceBucket" placeholder="Choose an option">
                    <i-select-option value="a" label="Option A" />
                    <i-select-option value="b" label="Option B" />
                    <i-select-option value="c" label="Option C" disabled />
                </i-select-->
            </i-form-group>

            <i-form-group>
                <i-form-label>Destination Bucket</i-form-label>
                <i-input :schema="formSchema.DestBucket" placeholder="dest bucket" />
                <!--i-select :schema="formSchema.DestBucket" placeholder="Choose an option">
                    <i-select-option value="a" label="Option A" />
                    <i-select-option value="b" label="Option B" />
                    <i-select-option value="c" label="Option C" disabled />
                </i-select-->
            </i-form-group>

            <i-form-group>
                <i-form-label>Memo</i-form-label>
                <i-textarea :schema="formSchema.Memo" placeholder="Write a comment.." />
            </i-form-group>

            <i-form-group>
                <i-form-label>Payee</i-form-label>
                <i-input :schema="formSchema.Payee" placeholder="Enter the payee" />
            </i-form-group>

            <i-form-group>
                <i-button type="submit">Submit</i-button>
            </i-form-group>
        </i-form>
    `,
    data: function(){
        return {
            formObjectClass: Transaction,
        };
    },
    methods: {
        doFormSubmit: doFormSubmit,
        parseFormData: parseFormData,
    },
});
Vue.component("bucket-form", {
    name: 'bucket-form',
    props: ['formSchema'],
    template: `
        <i-form v-model="formSchema" @submit="doFormSubmit(\'bucket\')">
            <i-form-group>
                <i-form-label>Name</i-form-label>
                <i-input :schema="formSchema.Name" placeholder="Type something.." />
            </i-form-group>

            <i-form-group>
                <i-form-label>Parent</i-form-label>
                <i-input :schema="formSchema.Parent" placeholder="Type something.." />
            </i-form-group>

            <i-form-group>
                <i-form-label>Ancestor</i-form-label>
                <i-input :schema="formSchema.Ancestor" :precision="2" placeholder="Type something.." />
            </i-form-group>

            <i-form-group>
                <i-button type="submit">Submit</i-button>
            </i-form-group>
        </i-form>
    `,
    data: function(){
        return {
            formObjectClass: Bucket,
        };
    },
    methods: {
        doFormSubmit: doFormSubmit,
        parseFormData: parseFormData,
    },
});

var vueInst = null;
function SPENT(){
    formatter = new Intl.NumberFormat(undefined, {
	  style: 'currency',
	  currency: 'USD',
	});

    var vm = new Vue({
        el: '#spent',
        store: dbStore,
        computed: {
            transactions: () => Transaction.all(),
            buckets: () => Bucket.query().with(['postedBalance']).all(),
            accounts: () => Account.all(),
            selectedBucket: function(){ return Bucket.query().whereId(this.selectedBucketID).with(['availableBalance', 'postedBalance', 'availableTreeBalance', 'postedTreeBalance']).first() },
        },
        data() {
            return {
                selectedBucketID: -1,
                transactionColumns: [
                    {title: "Status", path: "Status", sortable: true, component: "enum-table-cell", enumName: "TransactionStatus"},
                    {title: "Date", path: "TransDate", sortable: true},
                    {title: "Posted", path: "PostDate", sortable: true},
                    {title: "Amount", path: "Amount", sortable: true, component: "currency-table-cell"},
                    {title: "Type", path: "Type", sortable: true, component: "enum-table-cell", enumName: "TransactionType"},
                    {title: "Bucket", path: "", sortable: true, component: "bucket-table-cell"},
                    {title: "Memo", path: "Memo", sortable: true},
                    {title: "Payee", path: "Payee", sortable: true},
                ],
                transSchema: this.$inkline.form({
                    id: {},
                    Status: {},
                    TransDate: {},
                    PostDate: {},
                    Amount: {
                        value: 0,
                        validators: [
                            { rule: 'number', allowNegative: true, allowDecimal: true, message: "test" }
                        ],
                    },
                    SourceBucket: {},
                    DestBucket: {},
                    Memo: {},
                    Payee: {},
                    GroupID: {
                        value: -1,
                    },
                }),
                showTransactionFormModal: false,
                bucketColumns: [
                    {title: "Name", path: "Name", sortable: true},
                    {title: "Parent", path: "Parent", sortable: true},
                    {title: "Ancestor", path: "Ancestor", sortable: true},
                ],
                bucketSchema: this.$inkline.form({
                    id: {},
                    Name: {},
                    Parent: {},
                    Ancestor: {},
                }),
                showBucketFormModal: false,
                showBucketTableModal: false,
                accountTreeColumns: [
                    {title: "Name", path: "Name", sortable: false},
                    {title: "Balance", path: "postedBalance.value", sortable: false},
                ],
            };
        },
        watch: {
            selectedBucketID: function(id){
                // Request the transactions for the selected node
                requestManager.selectRecords("transaction", null, null, "SourceBucket == " + id + " OR DestBucket == " + id);
                dbStore.dispatch("sendDBRequest");

                propertyManager.selectRecords("property",
                [{"name": "SPENT.bucket.availableTreeBalance", "recordID": id},
                {"name": "SPENT.bucket.postedTreeBalance", "recordID": id},
                {"name": "SPENT.bucket.availableBalance", "recordID": id},
                {"name": "SPENT.bucket.postedBalance", "recordID": id}]);
                dbStore.dispatch("sendPropRequest");
            },
        },
        methods: {
            onSelAcc: function(a, b, c){
                this.selectedBucketID = b.ID || b.id;
            },
            setFormObject: function(obj, form){
                var self = this;
                form.fields.forEach(function(key){
                    let value = null;
                    if (obj){
                        value = getOrDefault(obj, key, undefined, true);
                    }
                    if(value !== undefined){
                        //form[key].value = value;
                        form.set(key, {
                            value: value,
                        }, { instance: self });
                    } else {
                        console.log("[SPENT] Failed to assign value to form element \'" + key + "\'");
                    }
                });
            },
            requestChanges: function(){
                var packet = propertyManager._createRequest_("refresh", "debug", [{"name": "SPENT.bucket.postedBalance"}], null, null);
                propertyManager._queueRequestPacket_(packet);

                var packet2 = requestManager._createRequest_("refresh", "debug", null, null, null);
                requestManager._queueRequestPacket_(packet2);

                dbStore.dispatch("sendPropRequest");
                dbStore.dispatch("sendDBRequest");
            },
            onFormSubmit(formName){
                switch(formName){
                    case "transaction":
                         this.showTransactionFormModal = false;
                         break;
                    case "bucket":
                        this.showBucketFormModal = false;
                        this.showBucketTableModal = true;
                }
            },
            onNewTransactionClick (){
                this.setFormObject(null, this.transSchema);
                this.showTransactionFormModal = true;
            },
            onNewBucketClick (){
                this.setFormObject(null, this.bucketSchema);
                this.showBucketFormModal = true;
            },
            onTransTableRowClick (event, row, rowIndex) { // Edit transaction
                this.setFormObject(row, this.transSchema);
                this.showTransactionFormModal = true;
            },
            onBucketTableRowClick (event, row, rowIndex) { // Edit transaction
                this.setFormObject(row, this.bucketSchema);
                this.showBucketTableModal = false;
                this.showBucketFormModal = true;

            },
        },
    });
    //vueInst = vm;
    requestManager.selectRecords("account");
    dbStore.dispatch("sendDBRequest").then( () => dbStore.dispatch("fetchAllBucketBalances"));
}

function bootstrapSPENT(){
    // The code that uses these enums isn't able to support delayed init so we request them and wait for the response before invoking the main SPENT() function
    enumManager.requestEnum("TransactionStatus");
    enumManager.requestEnum("TransactionType");
    dbStore.dispatch("sendEnumRequest").then( () => SPENT() );
};
