var formatter = null;

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

function bucketTreeGenerator(bucketsList, parentChildrenMap, currentNode){
    var nodeChildren = [];

    var currentNodeID = -1;
    if(currentNode != null){
        currentNodeID = currentNode["id"];
    }

    // Generate the children
    var childrenIDs = getOrDefault(parentChildrenMap, currentNodeID, null);
    if(childrenIDs){
        childrenIDs.forEach(function(childID){
            var bucket = getBucketForID(childID);
            var node = {
                id: bucket["id"],
                ancestor: bucket["Ancestor"],
                name: bucket["Name"],
                children: [],
            };
            nodeChildren.push(node);
        });
    }

    // Now it's time to create the parent node if we are doing the root;
    if (currentNode == null){
        currentNode = {
            id: -1,
            ancestor: null,
            name: "Root Node",
            children: nodeChildren,
        };
    } else {
        // Assign the parent it's children
        currentNode.children = nodeChildren;
    }

    // Now loop over the children and repeat
    nodeChildren.forEach(function(child){
        bucketTreeGenerator(bucketsList, parentChildrenMap, child);
    });
    return nodeChildren;
}

function getBucketForID(ID){
    //TODO: change this to be independent of the store
    var theBucket = null;
    dbStore.state.accounts.forEach(function(bucket){
        if(getOrDefault(bucket, "id", null) == ID){
            theBucket = bucket;
            return;
        }
    });
    return theBucket;
};

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

Vue.use(Vuex)

const dbStore = new Vuex.Store({
    strict: true,
    state: {
        transactions: [],
        accounts: [],
        properties: {},
        enumList: [],
        enumStore: {},
    },
    getters: {
        accountTree: function(state){
            var accounts = state.accounts;

            var parentChildList = {};
            accounts.forEach(function(account){
                var ID = getOrDefault(account, "id", null);
                var parentID = getOrDefault(account, "Parent", null);

                var siblingList = getOrDefault(parentChildList, parentID, new Set());
                siblingList.add(ID);
                parentChildList[parentID] = siblingList;
            });

            var accTree = bucketTreeGenerator(accounts, parentChildList, null);
            return accTree;
        },
        getProperties: function(state){
            return state.properties;
        },
        getEnumNameByValue: (state) => (value, enumKey) => {
            var enumID = state.enumList.indexOf(enumKey);
            if(enumID != -1){
                var result = getOrDefault(getOrDefault(state.enumStore[enumID], value, null), "name", null);
                return result;
            }
            return "Invalid Enum";
        },
    },
    mutations: {
        setTransactions: function(state, data){
            var action = data.action;
            if(action == "get"){
                state.transactions = data.data;
            } else if (action == "update"){
                // This is VERY slow; it needs redone
                data.data.forEach((item) => {
                    let ind = state.transactions.findIndex(x => x.id == item.id);
                    if (ind != -1){
                        let trans = state.transactions[ind]
                        Object.entries(item).forEach( (attrib) => Vue.set(trans, attrib[0], item[attrib[0]]) );
                    } else {
                        console.log("No transaction with id " + item.id + " was found in the store; Moving on...");
                    }
                });
            } else {
                alert("Error: Cannot commit transaction mutation: Unknown action \"" + action + "\"");
            }

        },
        setAccounts: function(state, data){
            var action = data.action;
            if(action == "get"){
                state.accounts = data.data;
            } else {
                alert("Error: Cannot commit transaction mutation: Unknown action \"" + action + "\"");
            }
        },
        setPropertyValues: function(state, data){
            console.log("running setPropertyValues");
            // Now we map the properties so they can be looked up by name before storing them
            data.data.forEach(function (item, index){
                // TODO: We should not use the property name as a key without sanitizing it first, as it comes directly from the web server;
                var propertyName = getOrDefault(item, "name", null);
                var propertyValue = getOrDefault(item, "value", undefined, true);

                console.log("parsing prop: " + propertyName + " Value: " + propertyValue + "; " + item);
                if (propertyName !== null && propertyValue !== undefined){
                    console.log("setting prop: " + propertyName + " Value: " + propertyValue);
                    Vue.set(state.properties, propertyName, {value: propertyValue});
                    //state.properties[propertyName] = {value: propertyValue};
                } else {
                    console.log("Error parsing property at loop index: " + index);
                }
            });
        },
        setEnumValue: function(state, params){
            console.log("running setEnumValues");

            var enumID = state.enumList.indexOf(params.enumName);
            if(enumID == -1){
                enumID = state.enumList.push(params.enumName) - 1;
            }
            console.log("setting enum: " + params.enumName + " Value: " + params.data + " Index: " + enumID);
            Vue.set(state.enumStore, enumID, params.data);
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
    },
})

function parseServerResponse(context, responseRecord){
    var type = responseRecord.type;
    var action = responseRecord.action;
    var data = responseRecord.data;
    var enumName = getOrDefault(responseRecord, "enum", null);

    var functionNameMap = {
        "account": "setAccounts",
        "transaction": "setTransactions",
        "property": "setPropertyValues",
        "enum": "setEnumValue",
    };
    var handlerName = getOrDefault(functionNameMap, type, null)
    if(handlerName){
        var payload = {action: action, data: data};
        if(enumName){
            payload["enumName"] = enumName
        }
        context.commit(handlerName, payload)
    } else {
        alert("Error: Cannot commit record: Unknown data type \"" + type + "\"");
    }

    /*if(type == "account"){
        context.commit("setAccounts", {data});
    } else if(type == "transaction"){
        context.commit("setTransactions", {data});
    } else if(type == "property"){
        context.commit("setPropertyValues", data);
    } else if(type == "enum"){
        context.commit("setEnumValue", {data: data, enumName: enumName});
    } */
}

Vue.component("tree-view", {
    template: `
        <ul class="tree-root">
            <tree-item v-for="(child, index) in nodes" :key="index" :item="child" @node-click="forwardClick" :currentnode="selectednode"></tree-item>
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
    }
});
Vue.component("tree-item", {
    template: `
        <li :class="{bold: isFolder}">
            <div :class="{nodeSelected: isSelected}"
            @click.self="select">
            {{ item.name }} {{ isSelected }}
            <span v-if="isFolder" @click.self="toggle">[{{ isOpen ? '-' : '+' }}]</span>
            </div>
            <ul v-show="isOpen" v-if="isFolder">
                <tree-item v-for="(child, index) in item.children" :key="index" :item="child" @node-click="forwardClick" :currentnode="currentnode">></tree-item>
            </ul>
        </li>
    `,
    props: {
        item: Object,
        currentnode: Number,
    },
    data: function() {
        return {
            isOpen: false,
        };
    },
    computed: {
        isFolder: function() {
            return this.item.children && this.item.children.length;
        },
        isSelected: function(){
            //console.log("Checking isSelected: " + (this.item.id == this.currentnode));
            return this.item.id == this.currentnode;
        }
    },
    methods: {
        toggle: function() {
            if (this.isFolder) {
                this.isOpen = !this.isOpen;
            }
        },
        select: function(){
            console.log("Tree Node Click: " + this.item.id)
            this.$emit("node-click", this.item.id);
        },
        forwardClick: function(id){
            console.log("Tree Node Forward Click: " + id);
            this.$emit("node-click", id);
        },
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
            return !getTransferDirection(this.row, this.$root.getSelectedBucketID());
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
                id = (transType == 1 ? this.row.DestBucket : this.row.SourceBucket);
            } else {
                id = (isDeposit ? this.row.SourceBucket : this.row.DestBucket);
            }

            return getBucketForID(id).Name;
        },
        isNegative (){
            return !getTransferDirection(this.row, this.$root.getSelectedBucketID());
        },
    },
});

function SPENT(){
    formatter = new Intl.NumberFormat(undefined, {
	  style: 'currency',
	  currency: 'USD',
	});

    var vm = new Vue({
        el: '#spent',
        store: dbStore,
        computed: {
            transactions (){
                return this.$store.state.transactions;
            },
            accountTree (){
                return this.$store.getters.accountTree;
            },
            bucketATB (){ return getOrDefault(this.$store.state.properties, "SPENT_bucket_availableTreeBalance", {value: null}).value},
            bucketPTB (){ return getOrDefault(this.$store.state.properties, "SPENT_bucket_postedTreeBalance", {value: null}).value},
            bucketAB (){ return getOrDefault(this.$store.state.properties, "SPENT_bucket_availableBalance", {value: null}).value},
            bucketPB (){ return getOrDefault(this.$store.state.properties, "SPENT_bucket_postedBalance", {value: null}).value},
        },
        data: {
            transactionForm: {
                visible: false,
                status: 0,
                date: "",
                postDate: "",
                amount: 0.0,
                sourceBucket: -1,
                destBucket: -1,
                memo: "",
                payee: "",
            },
            transactionColumns: [
                {title: "Status", path: "Status", sortable: true, component: "enum-table-cell", enumName: "TransactionStatus"},
                {title: "Date", path: "TransDate", sortable: true},
                {title: "Posted", path: "PostDate", sortable: true},
                {title: "Amount", path: "Amount", sortable: true, component: "currency-table-cell"},
                {title: "Type", path: "Type", sortable: true},
                {title: "Bucket", path: "", sortable: true, component: "bucket-table-cell"},
                // TODO: Quick fix to hide these rows
                {path: "SourceBucket", sortable: false},
                {path: "DestBucket", sortable: false},
                {title: "Memo", path: "Memo", sortable: true},
                {title: "Payee", path: "Payee", sortable: true},
            ],
            selectedBucketID: -1,
            visible1: false,
        },
        methods: {
            handleNodeClick: function(id){
                console.log("Tree Node: " + id);
                console.log("----------------");
                this.selectedBucketID = id;
                requestManager.selectRecords("transaction", null, null, "SourceBucket == " + id + " OR DestBucket == " + id);
                dbStore.dispatch("sendDBRequest");

                propertyManager.selectRecords("property",
                [{"name": "SPENT_bucket_availableTreeBalance", "bucket": this.selectedBucketID},
                {"name": "SPENT_bucket_postedTreeBalance", "bucket": this.selectedBucketID},
                {"name": "SPENT_bucket_availableBalance", "bucket": this.selectedBucketID},
                {"name": "SPENT_bucket_postedBalance", "bucket": this.selectedBucketID}]);
                dbStore.dispatch("sendPropRequest");
            },
            getSelectedBucketID: function(){
                return this.selectedBucketID;
            },
            requestChanges: function(){
                var packet = propertyManager._createRequest_("refresh", "debug", [{"name": "SPENT_bucket_postedBalance"}], null, null);
                propertyManager._queueRequestPacket_(packet);

                var packet2 = requestManager._createRequest_("refresh", "debug", null, null, null);
                requestManager._queueRequestPacket_(packet2);

                dbStore.dispatch("sendPropRequest");
                dbStore.dispatch("sendDBRequest");
            }
        }
    });
    requestManager.selectRecords("account");
    dbStore.dispatch("sendDBRequest");

}

// The code that uses these enums isn't able to support delayed init so we request them and wait for the response before invoking the main SPENT() function
enumManager.requestEnum("TransactionStatus");
enumManager.requestEnum("TransactionType");

// Problem: Vue will update everything that uses "$store.state.properties ...." anytime a new property is added, bringing the potential for massive lag spikes;
// Solution: Request every property we intend to use during runtime BEFORE the update handlers are registered.
propertyManager.selectRecords("property", [
                {"name": "SPENT_bucket_availableTreeBalance"},
                {"name": "SPENT_bucket_postedTreeBalance"},
                {"name": "SPENT_bucket_availableBalance"},
                {"name": "SPENT_bucket_postedBalance"}]);

// Wait for the property and enum requests to come back and be fully processed before starting SPENT
dbStore.dispatch("sendPropRequest").then( () => (dbStore.dispatch("sendEnumRequest").then( () => SPENT() )));