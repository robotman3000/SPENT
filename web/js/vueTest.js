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
        var promise = this._apiRequest_(this.requestPackets, function(data){
            self.parseAPIResponse(data);
        }, this.handleAPIError)
        this.requestPackets = []
        return promise;
    };

    this.parseAPIResponse = function(response){
        var self = this;
        var records = response.records;
        records.forEach(function(item, index){
            var action = item.action;
            var data = item.data;

            //alert(JSON.stringify(item));
        })
    };

    this.handleAPIError = function(data){alert("error!")};

    this._apiRequest_ = function(requestObj, suc, err){
        var self = this;
        return $.ajax({
            url: '/property/query',
            type: "POST",
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            data: JSON.stringify(requestObj),
            success: function(data) {
                if(data.successful == true){
                    /*if(suc){
                        suc(data)
                    }*/
                    self.parseAPIResponse(data)
                } else {
                    alert("Property Error: " + response.message);
                    if(err){
                        err(data)
                    }
                }
            },
            error: function(data) {
                alert("Server Error with property!! " + JSON.stringify(data));
                if(err){
                    err(data)
                }
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

    this.selectRecords = function(dataTypeName, fuzzyData, rules){
        //TODO: this should check that the function args are valid
        var packet = this._createRequest_("get", dataTypeName, fuzzyData, null, rules)
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

    this._createRequest_ = function(action, type, data, columns, rules){
        //TODO: Verify the input data and sanitize it
        var request = {
            action: action,
            type: type
        }

        var properties = [{name: "data", value: data, def: {}}, {name: "columns", value: columns, def: []}, {name: "rules", value: rules, def: {}}]
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
var requestManager = new APIRequestManager();

function getOrDefault(object, property, def){
    if (object){
        return (object[property] != undefined ? object[property] : def);
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

Vue.use(Vuex)

const dbStore = new Vuex.Store({
    state: {
        transactions: [],
        accounts: [],
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
        }
    },
    mutations: {
        setTransactions: function(state, data){
            state.transactions = data;
        },
        setAccounts: function(state, data){
            state.accounts = data;
        }
    },
    actions: {
        sendDBRequest(context){
            return requestManager.sendRequest().done(function(response){
                var self = this;
                var records = response.records;
                records.forEach(function(item, index){
                    var action = item.action;
                    var type = item.type;
                    var data = item.data;

                    if(type == "account"){
                        context.commit("setAccounts", data);
                    } else if(type == "transaction"){
                        context.commit("setTransactions", data);
                    } else {
                        alert("Error: Cannot commit data: Unknown data type \"" + type + "\"");
                    }
                })
            })
        },
    }
})

Vue.component("tree-view", {
    template: `
        <ul class="tree-root">
            <tree-item v-for="(child, index) in nodes" :key="index" :item="child"></tree-item>
        </ul>
    `,
    props: {
        nodes: Array,
    },
});
Vue.component("tree-item", {
    template: `
        <li :class="{bold: isFolder}"
            @click.self="toggle">
            {{ item.name }}
            <span v-if="isFolder">[{{ isOpen ? '-' : '+' }}]</span>
            <ul v-show="isOpen" v-if="isFolder">
                <tree-item v-for="(child, index) in item.children" :key="index" :item="child"></tree-item>
            </ul>
        </li>
    `,
    props: {
        item: Object
    },
    data: function() {
        return {
            isOpen: false
        };
    },
    computed: {
        isFolder: function() {
            return this.item.children && this.item.children.length;
        }
    },
    methods: {
        toggle: function() {
            if (this.isFolder) {
                this.isOpen = !this.isOpen;
            }
        },
    }
});

new Vue({
    el: '#spent',
    store: dbStore,
    computed: {
        transactions (){
            return this.$store.state.transactions;
        },
        accountTree (){
            return this.$store.getters.accountTree
        }
    },
    data: {
        visible1: false,
        transactionColumns: [
            {title: "Status", path: "Status", sortable: true},
            {title: "Date", path: "TransDate", sortable: true},
            {title: "Posted", path: "PostDate", sortable: true},
            {title: "Amount", path: "Amount", sortable: true},
            {title: "Bucket A", path: "SourceBucket", sortable: true},
            {title: "Bucket B", path: "DestBucket", sortable: true},
            {title: "Memo", path: "Memo", sortable: true},
            {title: "Payee", path: "Payee", sortable: true},
            {title: "Group", path: "GroupID", sortable: true},
            {title: "Is Transfer", path: "IsTransfer", sortable: true},
            {title: "Type", path: "Type", sortable: true},
        ],
        collapsed: false,
    },
});

requestManager.selectRecords("transaction");
requestManager.selectRecords("account");
dbStore.dispatch("sendDBRequest");