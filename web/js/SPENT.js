var enums = {};
var formatter = null;

function initGlobals(){
	//// Undefined causes it to use the system local
	formatter = new Intl.NumberFormat(undefined, {
	  style: 'currency',
	  currency: 'USD',
	});

	enums = { //TODO: This should be populated using an api request
		transactionStatus:  [
            "Uninitiated",
            "Submitted",
            "Post-Pending",
            "Complete"
        ],
        transactionType: [
            "Transfer", //0
            "Deposit", // 1
            "Withdrawal" //2
        ],
	}
}

function dateToStr(d){
    var month = '' + (d.getMonth() + 1),
        day = '' + d.getDate(),
        year = d.getFullYear();

    if (month.length < 2) month = '0' + month;
    if (day.length < 2) day = '0' + day;

    return [year, month, day].join('-');
}

function getOrDefault(object, property, def){
    if (object){
        return (object[property] != undefined ? object[property] : def);
    }
	return def;
}

function apiRequest(requestObj, suc, err){
	return $.ajax({
		url: '/database/apiRequest',
		type: "POST",
		contentType: "application/json; charset=utf-8",
		dataType: "json",
		data: JSON.stringify(requestObj),
		success: function(data) {
		    apiRequestSuccessful(data);
		    suc(data)
			//return data.data
		},
		error: function(data) {
			alert("Request Error!! " + JSON.stringify(data));
			err(data)
		}
	});
}

//TODO: The selAccount parameter is temporary until a proper API change for this type of data is designed
function createRequest(action, type, data, columns, rules, selAccount){
	//TODO: Verify the input data and sanitize it
	var request = {
		action: action,
		type: type
	}

    var properties = [{name: "data", value: data}, {name: "columns", value: columns}, {name: "rules", value: rules}]
    properties.forEach(function(item, index){
        if(item.value != undefined && item.value != null){
           request[item.name] = item.value;
            if(item.value.length < 1){
                request[item.name] = null;
            }
        }
    });

	if(selAccount != undefined && selAccount != null){
	   request.selAccount = selAccount;
	}

	request.debugTrace = new Error().stack;
	return request
}

function apiRequestSuccessful(response){
	if(response.successful == true){
		return true;
	}
	alert("API Error: " + response.message);
	return false;
}

function onDocumentReady() {
    // Initialize global variables
    initGlobals();

    Backbone.ajax = function(){
        var apiAction = null;
        switch(arguments[0].type){
            case "POST": // create
            case "PUT": // update
            case "DELETE": // delete
                apiAction = method
                break;
            case "GET": // read
                apiAction = "get"
            default:
                break;
        }

        console.log("AJAX: " + apiAction + " - " + arguments[0].url)
        var req = apiRequest(createRequest(apiAction, arguments[0].url), arguments[0].success, arguments[0].error)
        return req;
    }

    var UIState = Backbone.Model.extend({
        defaults: function(){
            return {
                selectedAccount: -1,
                bucketModalSelectedAccount: -1,
            }
        }
    })
    var uiState = new UIState;

    // Model Objects
    var Bucket = Backbone.Model.extend({
        defaults: function(){
            return {
                ID: null,
                Name: null,
                Parent: -1,
                Ancestor: -1,
            };
        },
    });
    var Buckets = Backbone.Collection.extend({
        model: Bucket,
        url: "bucket",
        parse: function(resp, options) {
            return resp.data;
        },
    });

    var Account = Bucket.extend({});
    var Accounts = Backbone.Collection.extend({
        model: Account,
        url: "account",
        parse: function(resp, options) {
            return resp.data;
        },
    });

    var Transaction = Backbone.Model.extend({
        defaults: function(){
            return {
                ID: null,
                Status: 0,
                TransDate: null,
                PostDate: null,
                SourceBucket: -1,
                DestBucket: -1,
                Memo: "",
                Payee: "",
            };
        },
    });
    var Transactions = Backbone.Collection.extend({
        model: Transaction,
        url: "transaction",
        parse: function(resp, options) {
            return resp.data;
        },
    });

    // Create instances of the model collections
    var accounts = new Accounts;
    var buckets = new Buckets;
    var transactions = new Transactions;

    // Base Views
    var BaseModelView = {
        model: null,
        setModel: function(newModel){
            this.model = newModel;
            this.trigger("modelChanged");
        },
        getModel: function(){
            return this.model;
        },
    };
    var TriggerButton = Backbone.View.extend({
        initialize: function(item, preClick){
            this.setElement(item)
            this.preClick = preClick;
        },
        events: {
            "click" : "triggerClick",
        },
        triggerClick: function(){
            if(this.preClick){
                this.preClick();
            }
            this.trigger("buttonClick")
        },
    });
    var DynamicSelectViewTemp = Backbone.View.extend({
        initUnselected: false,
        initialize: function(){
            this.on("modelChanged", this.modelChanged, this)
        },
        modelChanged: function(){
            this.listenTo(this.model, "update", this.render)
            this.listenTo(this.model, "reset", this.render)
        },
        render: function(){
            console.log("DynamicSelectView.render")
            this.$el.prop("disabled", true);

            this.$el[0].options.length=0
            //it[0].options.add(new Option("N/A", -1, true, (value == -1)));

            var value = -1; // TODO: this is a placeholder
            var self = this;
            this.model.where().forEach(function(ite, ind){
                self.$el[0].options.add(new Option(ite.get("Name"), ite.get("ID"), false, (value == ite.get("ID"))))
            });
            this.$el.prop("disabled", false);

            //TODO: This needs reimplemented; Feature [2]
            /*if (it.attr('name') == "DestBucket" || it.attr('name') == "SourceBucket") {
                $("#transactionTableType").change();
            } else {
                it.prop("disabled", false);
            }*/
        },
    });
    var DynamicSelectView = DynamicSelectViewTemp.extend(BaseModelView);

    var BaseModal = Backbone.View.extend({
        modalName: null,
        title: null,
        initialize: function(){
			// Get the modal
			if(this.modalName == null || this.modalName == undefined){
			    console.log("BaseModal.initialize: invalid modalName!!")
			}

			var modal = document.getElementById(this.modalName);
            this.setElement(modal)

            var self = this;
            this.triggers.forEach(function(item, index){
                var button = new TriggerButton(item);
                button.on("buttonClick", self.showModal, self)
            });
        },
        setTitle: function(title){
            this.title = title;
        },
        showModal: function(){
            this.render();
			this.$el.modal('show');
		},
		hideModal: function(){
			this.$el.modal('hide');
		},
		render: function(){
		    if (this.title == undefined){
				this.title = "No Title";
			}
			this.$el.find(".modal-title").text(this.title)
		},
		triggers: [],
    });
    var BaseFormTemp = Backbone.View.extend({
        formName: null,
        initialize: function(){
            if(this.formName == null || this.formName == undefined){
			    console.log("BaseForm.initialize: invalid formName!!")
			}

			var formDiv = $("#" + this.formName + "Div");
            var form = this.generateForm(formDiv);
            formDiv.append(form);
            this.setElement(form);

            this.on("modelChanged", this.render, this)
            // Create the modal buttons in the footer
            //TODO: This needs reimplemented; Feature [1]
            /*if (formDiv.data("submit")){
                var submitBtn = $('<button/>').attr({type: 'submit', class: 'btn btn-default btn-primary'});
                submitBtn.text('Submit')
                submitBtn.click(function(){
                    //editForm.submit();
                })
                //$("#" + tableName + "EditFormModal" + " .modal-footer").append(submitBtn)
            }*/
        },
        generateForm: function(){
            var cols = []
            var self = this;
            this.columns.forEach(function(item, index){
                if(item.visible != false){
                    var div = $("<div class='form-group'></div>");

                    var titleStr = (item.title ? item.title : item.name);
                    div.append($('<label>' + titleStr + '</label>').attr('for', item.title));

                    var input = null;
                    switch(item.type){
                        case "textbox": //TODO: textbox should actually be a textarea not a single line
                        case "text":
                            input = $("<input></input>").attr("type", "text");
                            break;
                        case "number":
                            input = $("<input></input>").attr("type", "number");
                            input.attr("step", (item.options ? getOrDefault(item.options, "step", 1) : 1))
                            break;
                        case "date":
                            input = $("<input></input>").attr("type", "date");
                            break;
                        case "select":
                            input = $("<select></select>");
                            var enumKey = (item.options ? getOrDefault(item.options, "enumKey", "") : "");
                            var optionsArray = getOrDefault(enums, enumKey, ["Invalid Enum: " + enumKey])
                            optionsArray.forEach(function(item, index){
                                var option = $('<option value="' + index + '">' + item + '</option>');
                                input.append(option);
                            });
                            break;
                            /*if(item.name == "Type"){ // TODO: This needs reimplemented; Feature [2]
                               select.change(function(data){
                                   //alert(this.value);
                                   sourceVisible = false;
                                   destVisible = false;
                                   switch(this.value){
                                       case "0":
                                           sourceVisible = true;
                                           destVisible = true;
                                           break;
                                       case "1":
                                           sourceVisible = false;
                                           destVisible = true;
                                           break;
                                       case "2":
                                           sourceVisible = true;
                                           destVisible = false;
                                           break;
                                   }
                                   $("#" + self.tableName + "SourceBucket").prop("disabled", !sourceVisible);
                                   $("#" + self.tableName + "DestBucket").prop("disabled", !destVisible);

                                   if(!sourceVisible){
                                       $("#" + self.tableName + "SourceBucket").val(-1)
                                   }

                                   if(!destVisible){
                                       $("#" + self.tableName + "DestBucket").val(-1)
                                   }
                               });
                            }*/
                        case "dynamicSelect":
                            input = $("<select></select>");
                            var dynamicSelect = new DynamicSelectView;
                            dynamicSelect.setElement(input);

                            var model = (item.options ? getOrDefault(item.options, "model", null) : null);
                            if(model){
                                dynamicSelect.setModel(model);
                            }
                            break;
                    }
                    if(input != null){
                        input.attr("id", self.tableName + item.name);
                        input.attr("name", item.name);
                        input.attr("class", "form-control");
                        input.attr("required", (item.required == true));
                        div.append(input);
                        cols.push(div);
                    }
                }
            });

            var form = $("<form></form>");
            form.attr("name", this.formName);
            cols.forEach(function(item, index){
                form.append(item);
            });
            return form;
        },
        render: function(){
			var data = (this.getModel() ?  this.getModel()[0].toJSON() : {});
			//alert(JSON.stringify(data));

			// Input Elements
			var inputs = this.$el.find("input").toArray();
			inputs.forEach(function(item, index){
				if (!(item.type == "submit")){
					var key = item.name;
					var oldValue = getOrDefault(data, key, "");
					if(oldValue.toDate){ //TODO: Verify the date processing logic is correct
						var d = new Date(1971,01,01);
						if(oldValue.toDate() < d){
							return "";
						}
						oldValue = dateToStr(oldValue.toDate());
					}
					$(item).val(oldValue);
				}
			});

			//Select Elements
			var inputs = this.$el.find("select").toArray();
			inputs.forEach(function(item, index){
				var key = item.name;
				var oldValue = getOrDefault(data, key, null);
				if(oldValue == null){
					item.selectedIndex = 0;
				} else {
					$(item).val(oldValue);
				}
			});
		},
		onSubmit: function(){
		    alert("Form Submit!!");
            var data = this.$el.serializeArray()

            //TODO: Create and implement a generic data validation system
            // Call the submit callback for the affected table
            console.log("Form Data: " + JSON.stringify(data))
            var result = this.submit(data);

            /*if(result == true){ //TODO: This needs reimplemented; Feature [3]
                hideModal(tableName + "EditFormModal");
            }*/
            // We return false to prevent the web page from being reloaded
            return false;
        },
        submit: function(data){},
        columns: [],
        events: {
            "submit" : "onSubmit",
        },
    });
    var BaseForm = BaseFormTemp.extend(BaseModelView);

    // Utility Views
    var ConfirmActionModalTemp = BaseModal.extend({
        modalName: "confirmActionModal",
        events: {
            "click #confirmActionModal-False" : "confirmFalse",
            "click #confirmActionModal-True" : "confirmTrue",
        },
        confirmTrue: function(){
            this._confirmHandler_(true)
        },
        confirmFalse: function(){
            this._confirmHandler_(false)
        },
		_confirmHandler_: function(result){
		    callback = this.getConfirmCallback();
			if(callback){
				callback(result);
			}
			this.hideModal()
		},
		setConfirmCallback: function(callback){
		    this.callback = callback;
		},
		getConfirmCallback: function(){
		    return this.callback;
		},
		setMessage: function(message){
		    this.message = message
		},
		getMessage: function(){
		    return this.message;
		},
		render: function(){
			$("#confirmActionModalText").text(this.message)
		}
    });
    var ConfirmActionModal = ConfirmActionModalTemp.extend(BaseModelView);

    // Account Views
    var AccountTreeView = Backbone.View.extend({
        el: $("#accountTree"),
        initialize: function(){
            this.$el.treeview({
                expandIcon: "fas fa-plus",
                collapseIcon: "fas fa-minus",
                nodeIcon: "",
                emptyIcon: "",
                selectedIcon: "",

                preventUnselect: true,
                allowReselect: false,
                showTags: true,
                tagsClass: "badge badge-pill badge-secondary float-right",
            });

            this.$el.on("nodeSelected", this.nodeSelected)

            this.listenTo(accounts, "add", this.nodeAdded)
            this.listenTo(accounts, "remove", this.nodeRemoved)

            this.listenTo(buckets, "add", this.nodeAdded)
            this.listenTo(buckets, "remove", this.nodeRemoved)
        },
        nodeAdded: function(model, collection, options){
            var nodes = this.responseToTreeNode([model.attributes])
            this.$el.treeview(true).addNode(nodes)
            //console.log(JSON.stringify(options))
        },
        nodeRemoved: function(model, collection, options){
            var nodes = this.responseToTreeNode([model.attributes])
            this.$el.treeview(true).removeNode(nodes)
            //console.log(JSON.stringify(options))
        },
        nodeSelected: function(event, node){
            uiState.set("selectedAccount", node.dataAttr.ID)
        },
        responseToTreeNode(data){
            var results = []
            data.forEach(function(item, index) {
                var children = [];
                item.Children.forEach(function(it, ind){
                    children.push({"id": it})
                });
                results.push({"text": item.Name, "lazyLoad": (item.Children.length > 0), dataAttr: {"childrenIDs": item.Children, "ID": item.ID}, "tags": [item.Balance]})
            });
            return results
        },
    });
    var AccountStatusView = Backbone.View.extend({
        el: $("#accountStatusText"),
        initialize: function(){
            this.listenTo(uiState, "change:selectedAccount", this.render);
        },
        render: function(){
            console.log("Render: AccountStatusView")
        	if (uiState.get("selectedAccount") != undefined) {
        	    var account = accounts.where({ID: uiState.get("selectedAccount")});

        	    if(!account || account.length < 1){
        	        account = buckets.where({ID: uiState.get("selectedAccount")});
        	    }

        	    if(account && account.length > 0){
        	        this.$el.text("Available: \$" + account[0].get("Balance") + ", Posted: \$" + account[0].get("PostedBalance"));
        	        return;
        	    }
            }
            this.$el.text("Error displaying balance");
        },
    });

    // Table Views
    var BaseTableView = Backbone.View.extend({
        model: null,
        apiDataType: null,
        initialize: function(actionModals){
        	console.log("BaseTableView.initialize: " + this.tableName);
        	this.setElement($("#" + this.tableName))

            var self = this;

            updateTable = function(){
                console.log("Loading Data: " + this.tableName);
                self.$el.jsGrid("loadData");
            };

            this.listenTo(this.model, "update", updateTable);
            this.listenTo(this.model, "reset", updateTable);

            var fields = this.apiTableSchemaToColumns();
            fields.push({
                type: "control",
                modeSwitchButton: false,
                editButton: true,
                headerTemplate: function() {
                    var div = $("<div>").attr("role", "group").attr("class", "btn-group");

                    var addBtn = $("<button>").attr("type", "button").attr("class", "btn");
                    addBtn.append($("<i>").attr("class", "fas fa-plus-circle"))
                    div.append(addBtn);

                    if (actionModals["new"]){
                        var button = new TriggerButton(addBtn, function(){
                            actionModals["new"].modal.setTitle("New " + self.apiDataType)
                            actionModals["new"].form.setModel(null);
                        });
                        button.on("buttonClick", actionModals["new"].modal.showModal, actionModals["new"].modal)
                    }

                    if(self.tableName == "transactionTable"){
                        var filterBtn = $("<button>").attr("type", "button").attr("class", "btn");
                        filterBtn.append($("<i>").attr("class", "fas fa-filter"))
                        div.append(filterBtn);

                        if (actionModals["filter"]){
                            var button = new TriggerButton(filterBtn);
                            button.on("buttonClick", actionModals["filter"].modal.showModal, actionModals["filter"].modal)
                        }
                    }
                    return div;
                },
                itemTemplate: function(a, b){
                    var div = $("<div>").attr("role", "group").attr("class", "btn-group");

                    var editBtn = $("<button>").attr("type", "button").attr("class", "btn");
                    editBtn.append($("<i>").attr("class", "fas fa-edit"))
                    div.append(editBtn);

                    if (actionModals["edit"]){
                        var button = new TriggerButton(editBtn, function(){
                            var row = self.$el.jsGrid('rowByItem', b)
                            actionModals["edit"].modal.setTitle("Edit " + self.apiDataType)
                            actionModals["edit"].form.setModel(self.model.where({ID: row.data("JSGridItem").ID}));
                        });
                        button.on("buttonClick", actionModals["edit"].modal.showModal, actionModals["edit"].modal)
                    }

                    var deleteBtn = $("<button>").attr("type", "button").attr("class", "btn");
                    deleteBtn.append($("<i>").attr("class", "fas fa-trash"))
                    div.append(deleteBtn);

                    if (actionModals["delete"]){
                        var button = new TriggerButton(deleteBtn, function(){
                            var row = self.$el.jsGrid('rowByItem', b)
                            actionModals["delete"].modal.setTitle("Delete " + self.apiDataType)
                            actionModals["delete"].form.setModel(self.model.where({ID: row.data("JSGridItem").ID}));
                            actionModals["delete"].form.setMessage("Confirm Row Delete\n" + JSON.stringify(row.data("JSGridItem")));
                            actionModals["delete"].form.setConfirmCallback(function(allClear){
                                if(allClear){
                                    self.$el.jsGrid("deleteItem", row).done(function() {
                                        console.log("delete completed");
                                    });
                                }
                            });
                        });
                        button.on("buttonClick", actionModals["delete"].modal.showModal, actionModals["delete"].modal)
                    }

                    return div;
                }
            })

            var table = this.$el.jsGrid({
                fields: fields,
                autoload: false,
                controller: {
                    loadData: function (filter){
                        var selID = null;
                        try {
                            selID = (self.apiDataType == "transaction" ? uiState.get("selectedAccount") : uiState.get("bucketModalSelectedAccount"))
                        }
                        catch(err) {
                            console.log(err.message);
                        }

                        /*var rules = null;
                        if(getTableData(tableName).apiDataType == "transaction"){
                            rules = getTransactionFilterRules();
                        }*/


                        var result = [];
                        //if(selID != null && selID > -1){
                            self.model.where().forEach(function(item, index){
                                result.push(item.toJSON());
                            });
                        //}
                        return Promise.resolve(result);
                    },
                    /*insertItem: function (data){
                        return apiRequest(createRequest("create", getTableData(tableName).apiDataType, [data])).then(function(data){
                            return data.data[0];
                        });
                    },
                    updateItem: function (data){
                        return apiRequest(createRequest("update", getTableData(tableName).apiDataType, [data])).then(function(data){
                            return data.data[0];
                        });
                    },
                    deleteItem: function (tableRow){
                        //TODO: This sends the entire row, it only needs to send the ID. This will reduce the request size and increase performance with sending batch deletes
                        return apiRequest(createRequest("delete", getTableData(tableName).apiDataType, [tableRow])).then(function(data){
                            return data.data[0];
                        });
                    }*/
                },

                width: "100%",
                height: "auto",

                heading: true,
                filtering: false,
                inserting: false,
                editing: true,
                selecting: true,
                sorting: true,
                paging: false,
                pageLoading: false,

                rowClass: function(item, itemIndex) {}, //TODO: Use this to implement row color based on status
                rowClick: function(data){}, // This must be empty

                noDataContent: "No Data",

                confirmDeleting: false, // Disable the builtin delete confirm because we have our own

                invalidNotify: function(args) {},
                invalidMessage: "Invalid data entered!",

                loadIndication: true,
                loadIndicationDelay: 100,
                loadMessage: "Please, wait...",
                loadShading: true,

                updateOnResize: true,

                //rowRenderer: null, // Use this to implement column condensing on small screens
                //headerRowRenderer: null, // This might be useful

                onInit: function(args){
                    console.log("Initialized Table: " + self.tableName);
                }
            });
        },
        /*formCallback: function(tableRow, data){
            if (tableRow){
                $("#" + tableName).jsGrid("updateItem", tableRow, this.cleanRowData(data)).done(function() {
                    console.log("update completed");
                });
            } else {
                $("#" + tableName).jsGrid("insertItem", this.cleanRowData(data)).done(function() {
                    console.log("insert completed");
                });
            }
            //TODO: make this actually reflect whether the callback completed sucessfully
            return true;
        },*/
        apiTableSchemaToColumns: function(){
            var columns = []
            this.columns.forEach(function(item, index){
                var obj = {"name": (item.name ? item.name : item.title ), "title": item.title};
                if(item.visible != undefined){
                   obj.visible = item.visible
                }

                var formatter = getOrDefault(this.formatters, item.name, null);
                if(formatter != null){
                    obj.cellRenderer = function(value, rowData){
                        return '<td>' + formatter(value, rowData) + '</td>';
                    }
                }

                switch(item.type){
                    case "enum":
                        obj.type = "text"
                        obj.cellRenderer = function(value, rowData){
                            var enumKey = (item.options ? getOrDefault(item.options, "enumKey", "") : "");
                            var optionsArray = getOrDefault(enums, enumKey, ["Invalid enum: " + enumKey]);
                            return '<td>' + optionsArray[value] + '</td>';
                        };
                        break;
                    default:
                        obj.type = item.type;
                        break;
                }
                columns.push(obj);
            });
            return columns;
        },
        /*cleanRowData: function(data){
            // This converts objects of format [{name: ***, value: ***}, ..., ...]
            // to {The name: The value, The next name: The next value}
            var obj = {};

            // This loop style is used because "data" doesn't have .forEach or .length
            // for some reason
            for(var index = 0; data[index] != undefined; index++){
                obj[data[index].name] = data[index].value;
            }
            return obj;
        },*/
        formatters: {},
        columns: [],
    });

    var TransactionTable = BaseTableView.extend({
        model: transactions,
        tableName: "transactionTable",
        apiDataType: "transaction",
        initialize: function(actionModals){
            BaseTableView.prototype.initialize.apply(this, [actionModals]);
            this.listenTo(uiState, "change:selectedAccount", updateTable); //TODO: ??
        },
        formatters: {
            "Type": function(value, rowData){
                var fromToStr = "";
                if (value == "0"){//Transfer
                    fromToStr = (this.getTransferDirection(rowData, getSelectedAccount()) ? " from " : " to ");
                } else { // Other
                    fromToStr = (value == "2" ? " from " : " to ")
                }
                return enums["transactionTable"]["Type"][value] + fromToStr;
            },
            "Amount": function(value, rowData){
                var isDeposit = this.getTransferDirection(rowData, getSelectedAccount());
                if (isDeposit){
                    // If deposit
                    return formatter.format(value);
                }
                return formatter.format(value * -1);
            },
            "Bucket": function(value, rowData){
                var id = -2; //This value will cause the name func to return "Invalid ID"

                var transType = rowData.Type;
                var isDeposit = this.getTransferDirection(rowData, getSelectedAccount());
                if(transType != 0){
                    id = (transType == 1 ? rowData.DestBucket : rowData.SourceBucket);
                } else {
                    id = (isDeposit ? rowData.SourceBucket : rowData.DestBucket);
                }

                //var par = getBucketParentForID(id);
                //if(par != -1){
                return getBucketNameForID(id);
                //} else {
                    //rowData.bucketSort = "Unassigned";
                //}//
            },
            "TransDate": function(value, rowData){
                if(rowData.PostDate.toDate){
                    var d = new Date(1971,01,01);
                    if(rowData.PostDate.toDate() < d){
                        return "N/A";
                    }
                    return rowData.PostDate.format("YYYY-MM-DD");
                }
                return value;
            },
        },
        columns: [
            {name: "ID", visible: false},
            {name: "Status", title: "Status", type: "enum", breakpoints:"xs sm md", options: {enumKey: "transactionStatus"}},
            {name: "TransDate", title: "Date", type: "date", breakpoints:"xs", options: {formatString:"YYYY-MM-DD"}},
            {name: "PostDate", title: "Posted", type: "date", breakpoints:"xs sm md", options: {formatString:"YYYY-MM-DD"}},
            {name: "Amount", title: "Amount", type: "number", breakpoints:""},
            {name: "Type", title: "Type", type: "text", breakpoints:"xs sm md"},
            {title: "Bucket", type: "text", breakpoints:"xs sm md"},
            {name: "Memo", title: "Memo", type: "text", breakpoints:""},
            {name: "Payee", title: "Payee", type: "text", breakpoints:"xs sm"},
        ],
        getTransferDirection: function(rowData, node){
            // True = Money Coming in; I.E. a positive value
            // False = Money Going out; I.E. a negative value
            var ID = -1;
            if (node.dataAttr){
                ID = node.dataAttr.ID;
            }
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
        },
    });
    var BucketTable = BaseTableView.extend({
        model: buckets,
        modalName: "bucketTableModal",
        tableName: "bucketTable",
        apiDataType: "bucket",
        initialize: function(actionModals){
            BaseTableView.prototype.initialize.apply(this, [actionModals]);
            this.listenTo(uiState, "change:bucketModalSelectedAccount", updateTable); //TODO: ??
        },
        events: {
            "click bucketTableModalToggle" : "showModal"
        },
        formatters: {
            "Parent": function(value, rowData){
                return getBucketNameForID(value);
            },
        },
        columns: [
            {name: "ID", visible: false},
            {name: "Name", title: "Name", type: "text"},
            {name: "Parent", title: "Parent", type: "text"}
        ],
    });
    var AccountTable = BaseTableView.extend({
        model: accounts,
        tableName: "accountTable",
        apiDataType: "account",
        columns: [
            {name: "ID", visible: false},
            {name: "Name", title: "Name", type: "text"}
        ],
    });

    // Form Views
    var BaseTableEditForm = BaseForm.extend({});

    var TransactionTableEditForm = BaseTableEditForm.extend({
        formName: "transactionTableEditForm",
        tableName: "transactionTable",
        columns: [
            {name: "ID", visible: false},
            {name: "Status", title: "Status", type: "select", required: true, options: {enumKey: "transactionStatus"}},
            {name: "TransDate", title: "Date", type: "date", required: true},
            {name: "PostDate", title: "Posted", type: "date"},
            {name: "Amount", title: "Amount", type: "number", options: {step: 0.01}},
            {name: "Type", title: "Type", type: "select", required: true, options: {enumKey: "transactionType"}},
            {title: "Source", name: "SourceBucket", required: true, type: "dynamicSelect", options: {model: accounts}},
            {title: "Destination", name: "DestBucket", required: true, type: "dynamicSelect", options: {model: accounts}},
            {name: "Memo", title: "Memo", type: "textbox"},
            {name: "Payee", title: "Payee", type: "text"},
        ]
    });
    var BucketTableEditForm = BaseTableEditForm.extend({
        formName: "bucketTableEditForm",
        tableName: "bucketTable",
        columns: [
            {name: "ID", visible: false},
            {name: "Name", title: "Name", type: "text", required: true},
            {name: "Parent", title: "Parent", required: true, type: "dynamicSelect", options: {model: accounts}}
        ],
    });
    var AccountTableEditForm = BaseTableEditForm.extend({
        formName: "accountTableEditForm",
        tableName: "accountTable",
        columns: [
            {name: "ID", visible: false},
            {name: "Name", title: "Name", type: "text", required: true}
        ],
    });

    // Modals
    var AccountTableModal = BaseModal.extend({
        title: "Accounts",
        modalName: "accountTableModal",
        triggers: [
            "#accountTableModalToggle"
        ]
    });
    var AccountTableFormModal = BaseModal.extend({
        modalName: "accountTableEditFormModal",
    });

    var BucketTableModal = BaseModal.extend({
        title: "Buckets",
        modalName: "bucketTableModal",
        triggers: [
            "#bucketTableModalToggle"
        ]
    });
    var BucketTableFormModal = BaseModal.extend({
        modalName: "bucketTableEditFormModal",
    });

    var TransactionTableFormModal = BaseModal.extend({
        modalName: "transactionTableEditFormModal",
    });

    // Other
    var TransactionTableFilterModal = BaseModal.extend({
        title: "Transaction Filters",
        modalName: "transactionTableFilterModal",
        placeHolder: function(){
            $('#transactionTableFilter').queryBuilder({
                filters: [
                    {
                        id: 'status',
                        label: 'Status',
                        type: 'integer',
                        input: 'select',
                        values: {
                          1: 'Uninitiated',
                          2: 'Submitted',
                          3: 'Post-Pending',
                          4: 'Complete',
                        },
                        operators: ['equal', 'not_equal', 'less', 'less_or_equal', 'greater', 'greater_or_equal', 'between', 'not_between']
                    },
                    {
                        id: 'type',
                        label: 'Type',
                        type: 'integer',
                        input: 'select',
                        values: {
                          1: 'Transfer',
                          2: 'Deposit',
                          3: 'Withdrawal',
                        },
                        operators: ['equal', 'not_equal']
                    },
                    {
                        id: 'amount',
                        label: 'Amount',
                        type: 'double',
                    },
                    {
                        id: 'payee',
                        label: 'Payee',
                        type: 'string',
                        operators: ['equal', 'not_equal', 'begins_with', 'not_begins_with', 'contains', 'not_contains', 'ends_with', 'not_ends_with', 'is_empty', 'is_not_empty', 'is_null', 'is_not_null'],
                    },
                    {
                        id: 'tag',
                        label: 'Tag',
                        type: 'string',
                        operators: ['equal', 'not_equal', 'begins_with', 'not_begins_with', 'contains', 'not_contains', 'ends_with', 'not_ends_with', 'is_empty', 'is_not_empty', 'is_null', 'is_not_null'],
                    },
                    {
                        id: 'date',
                        label: 'Date',
                        type: 'date',
                        validation: {
                          format: 'YYYY-MM-DD'
                        },
                        plugin: 'datepicker',
                        plugin_config: {
                          format: 'yyyy-mm-dd',
                          todayBtn: 'linked',
                          todayHighlight: true,
                          autoclose: true
                        }
                    },
                    {
                        id: 'postdate',
                        label: 'Post Date',
                        type: 'date',
                        validation: {
                          format: 'YYYY-MM-DD'
                        },
                        plugin: 'datepicker',
                        plugin_config: {
                          format: 'yyyy-mm-dd',
                          todayBtn: 'linked',
                          todayHighlight: true,
                          autoclose: true
                        }
                    },
                    {
                        id: 'sourcebucket',
                        label: 'Source',
                        type: 'integer',
                    },
                    {
                        id: 'destbucket',
                        label: 'Destination',
                        type: 'integer',
                    }
                ],
                plugins: [
                    'invert',
                    'not-group'
                ]
            });

            $('#btn-get').on('click', function() {
                 alert(JSON.stringify(getTransactionFilterRules(), null, 2));
            });
        },
        getTransactionFilterRules: function(){
            var result = $('#transactionTableFilter').queryBuilder('getRules');

            if ($.isEmptyObject(result)) {
                return null;
            }
            return result;
        },
    });

    var BucketTableAccountSelect = DynamicSelectView.extend({
        el: $("#bucketEditAccountSelect"),
        initUnselected: false,
    });

    // Initialize the views in order of dependency
    var actionConfirmationModal = new ConfirmActionModal;

    var accountTree = new AccountTreeView;

    var accountStatusViewInst = new AccountStatusView;

    var transactionFilterModal = new TransactionTableFilterModal();
    var transactionEditForm = new TransactionTableEditForm;
    var transactionEditFormModal = new TransactionTableFormModal;
    var transactionTable = new TransactionTable({
        "filter" : {form: transactionFilterModal, modal: transactionFilterModal},
        "edit" : {form: transactionEditForm, modal: transactionEditFormModal},
        "new" : {form: transactionEditForm, modal: transactionEditFormModal},
        "delete" : {form: actionConfirmationModal, modal: actionConfirmationModal},
    });

    var bucketTableModal = new BucketTableModal;
    var bucketTableAccountSelect = new BucketTableAccountSelect;
    var bucketEditForm = new BucketTableEditForm;
    var bucketEditFormModal = new BucketTableFormModal;
    var bucketTable = new BucketTable({
        "edit": {form: bucketEditForm, modal: bucketEditFormModal},
        "new" : {form: bucketEditForm, modal: bucketEditFormModal},
        "delete" : {form: actionConfirmationModal, modal: actionConfirmationModal},
    });

    var accountTableModal = new AccountTableModal;
    var accountEditForm = new AccountTableEditForm;
    var accountEditFormModal = new AccountTableFormModal;
    var accountTable = new AccountTable({
        "edit": {form: accountEditForm, modal: accountEditFormModal},
        "new" : {form: accountEditForm, modal: accountEditFormModal},
        "delete" : {form: actionConfirmationModal, modal: actionConfirmationModal},
    });

    // Fetch the data from the server
    accounts.fetch();
    buckets.fetch();
    transactions.fetch({reset: true});

    bucketTableAccountSelect.setModel(accounts);

    /* Selects
    Account+Bucket Select (Transaction Edit Form [SourceBucket, DestBucket])
    Bucket Select (Bucket Edit Form [Parent])
    */

}