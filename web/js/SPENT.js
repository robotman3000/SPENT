var enums = {};
var formatter = null;
var crossModelUupdateMap = {};

function initGlobals(){
	//// Undefined causes it to use the system local
	formatter = new Intl.NumberFormat(undefined, {
	  style: 'currency',
	  currency: 'USD',
	});

	enums = { //TODO: This should be populated using an api request
		transactionStatus:  [
		    "Void",
            "Uninitiated",
            "Submitted",
            "Post-Pending",
            "Complete",
            "Reconciled",
        ],
        transactionType: [
            "Transfer", //0
            "Deposit", // 1
            "Withdrawal" //2
        ],
	}

	/*crossModelUupdateMap = {
	    transaction: {
	        // If "foreignKey" isn't defined then we update all the models of "foreignType"
	        {action: "change", property: "Amount", foreignType: "bucket", foreignMatchKey: "Balance"},
	        {action: "change", property: "Amount", foreignType: "bucket", foreignMatchKey: "PostedBalance"},
	        {action: "change", property: "Amount", foreignType: "account", foreignMatchKey: "Balance"},
	        {action: "change", property: "Amount", foreignType: "account", foreignMatchKey: "PostedBalance"},

	        {action: "create", foreignMatch: "bucket"},
	        {action: "delete", foreignMatch: "bucket"},
	    },
	    bucket: {
	        {action: "change", property: "Name", foreignKey: "ID", foreignMatch: "transaction", foreignMatchKey: "SourceBucket"},
	        {foreignKey: "Name", foreignMatch: "transaction", foreignMatchKey: "DestBucket"},
	    }
	}*/
}

function dateToStr(d){
    var month = '' + (d.getMonth() + 1),
        day = '' + d.getDate(),
        year = d.getFullYear();

    if (month.length < 2) month = '0' + month;
    if (day.length < 2) day = '0' + day;

    return [year, month, day].join('-');
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

function getOrDefault(object, property, def){
    if (object){
        return (object[property] != undefined ? object[property] : def);
    }
	return def;
}

function cleanData(data){
    // This converts objects of format [{name: ***, value: ***}, ..., ...]
    // to {The name: The value, The next name: The next value}
    var obj = {};

    // This loop style is used because "data" doesn't have .forEach or .length
    // for some reason
    for(var index = 0; data[index] != undefined; index++){
        obj[data[index].name] = data[index].value;
    }
    return obj;
};

function findModelsWhere(collections, filter){ // "OR" based results
    var result = null;
    if(collections && collections.length > 0){
        collections.forEach(function(item, index){
            if(result == null){
                var models = item.where(filter);
                if(models && models.length > 0){
                    result = models;
                }
            }
        });
    }
    return result;
}

//function findCollectionsWhere(collections, filter){} // "AND" based results

function getBucketNameForID(accounts, buckets, id){
    var models = findModelsWhere([accounts, buckets], {ID: id});
    if(models != null && models.length > 0){
        return models[0].get("Name");
    }
    return "Invalid ID: " + id;
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
		    if(suc){
		        suc(data)
		    }
		},
		error: function(data) {
			alert("Request Error!! " + JSON.stringify(data));
			if(err){
		        err(data)
		    }
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
    var createTriggerButton = function(item){
        var btn = $("<button>").attr("type", "button").attr("class", "btn");
        btn.append($("<i>").attr("class", item.cssClass))
        var button = new TriggerButton(btn, item.preClick);

        item.listeners.forEach(function(item, index){
            item.listener.listenTo(button, "buttonClick", item.callback)
        });

        return button;
    };
    var arrayToSelectOptions = function(array){
        var value = -1; //TODO: Placeholder
        var options = [];
        array.forEach(function(item, index){
            options.push({text: item, value: index, defaultSelected: false, selected: (value == item)});
        });
        return options;
    };
    var methodMap = {
        create: 'create',
        update: 'update',
        patch: 'update',
        delete: 'delete',
        read: 'get'
    };

    Backbone.sync = function(method, model, options){
        // Pass along `textStatus` and `errorThrown` from jQuery.
        var error = getOrDefault(options, "error", null);
        options.error = function(xhr, textStatus, errorThrown) {
            options.textStatus = textStatus;
            options.errorThrown = errorThrown;
            if (error) error.call(options.context, xhr, textStatus, errorThrown);
        };

        var apiAction = methodMap[method];
        var recordType = _.result(model, 'url') || urlError();
        var data = null;
        var requestColumns = options.columns || null;
        var rules = options.rules || null;

        var changed = false;
        switch (method){
            case "update":
            case "patch":
                changed = true;
            case "create":
                data = [model.asJSON({changed: changed})];
                break;
            case "delete":
                data = [{ID: model.get("ID")}];
                break;
            case "read": // TODO: This "case" doesn't account for the servers ability to return based on a list of id's
            default:
                data = null;
                break;
        }

        console.log("AJAX: " + apiAction + " - " + recordType)
        var req = apiRequest(createRequest(apiAction, recordType, data, requestColumns, rules), options.success, options.error)
        model.trigger('request', model, req, options);
        return req;
    };

    var UIState = Backbone.Model.extend({
        defaults: function(){
            return {
                selectedAccount: -1,
                bucketModalSelectedAccount: -1,
            }
        }
    })
    var uiState = new UIState;

    var TableRowRenderable = Object.create(null);
    TableRowRenderable.renderTR = function(){
        // this = The row view
        var self = this;
        var model = this.getModel();
        if(model){
            this.$el.empty(); //TODO: Rather than replacing the row, we should change the existing one

            this.$el.addClass("collapse");

            var gID = model.get("GroupID") || -1;
            if (gID != -1){
                this.$el.addClass("group" + gID);
            } else {
                this.$el.addClass("show");
            }
            console.log("TableRowRenderable.renderTR: " + this.parentView.apiDataType + ", ID: " + model.get("ID"))

            var rowSelf = this;

            var formatterFunction = function(value, model, formatter){
                var result = {text: value};
                if(formatter){
                    result = formatter(value, model.toJSON());
                }
                var tag = getOrDefault(result, "tag", "span");
                var text = getOrDefault(result, "text", "Format Error");
                var classes = getOrDefault(result, "class", "");

                var elem = $("<" + tag + ">").attr("class", classes).text(text);
                elem.addClass("SPENT-cell-value")
                return elem;
            };

            this.parentView.columns.forEach(function(item, index){
                if(!(item.visible == false)){
                    var formatter = getOrDefault(self.parentView.formatters, item.name, null);
                    var value = formatterFunction(model.get(item.name), model, formatter); //TODO: switch to passing the model rather than the json

                    var td = $("<td>");
                    var responsive = getOrDefault(item, "responsive", null);

                    var newValue = value;

                    var columnName = $("<h6>").attr("class", "responsive-visible SPENT-responsive-cell-title").text(item.title + ": ");
                    newValue = $("<div>").append(columnName).append(value);

                    if(responsive){
                        var shouldHide = getOrDefault(responsive, "hide", false);
                        if(shouldHide){
                            td.addClass("responsive-hidden");
                        }
                    }
                    td.append(newValue);
                    rowSelf.$el.append(td);
                }
            });
            var div = this._createActionButtons(this.buttons)
            this.$el.append($("<td>").append(div));
        } else {
            console.log("Failed to render row");
        }
    };

    // Model Objects
    var BaseModel = Backbone.Model.extend({
        initialize: function(){
            this.set("id", this.get("ID"));
        },
        url: function() {
          var base = _.result(this.collection, 'url') || urlError();
          return base;
        },
        asJSON: function(options){
            var keys = Object.keys(this.defaults());
            var object = {};
            var attrib = cleanData(this.changedAttributes());
            var self = this;
            keys.forEach(function(key, index){
                var value = undefined;
                if(getOrDefault(options, "changed", false) && attrib[key]){
                    value = attrib[key];
                } else {
                    value = self.get(key);
                }
                object[key] = value;
            });
            return object;
        },
        parse: function(response, options){
            var result = response
            if(getOrDefault(options, "isRaw", true)){
               result = response.data[0];
            }

            if(getOrDefault(result, "ID", null) != null){
                result["id"] = result["ID"];
            }

            return result;
        },
    }).extend(TableRowRenderable);
    var BaseCollection = Backbone.Collection.extend({
        parse: function(resp, options) {
            options.isRaw = false;
            var newData = [];
            resp.data.forEach(function(item, index){
                if(getOrDefault(item, "ID", null) != null){
                    item["id"] = item["ID"];
                }
                newData.push(item);
            });

            return newData;
        },
        // Credit to https://stackoverflow.com/a/21434708 for the comparator function
        comparator: function(a, b) {
          var sampleDataA = a.get(this.sortKey),
              sampleDataB = b.get(this.sortKey);
          if (this.reverseSortDirection) {
            if (sampleDataA > sampleDataB) { return -1; }
            if (sampleDataB > sampleDataA) { return 1; }
            return 0;
          } else {
            if (sampleDataA < sampleDataB) { return -1; }
            if (sampleDataB < sampleDataA) { return 1; }
            return 0;
          }
        },
        sortKey: "",
        reverseSortDirection: false,
    });

    var Bucket = BaseModel.extend({
        defaults: function(){
            return {
                ID: null,
                Name: null,
                Parent: -1,
                Ancestor: -1,
            };
        },
        getAncestorName: function(){
            var ancestor = accounts.get(this.get("Ancestor"));
            if(ancestor){
                return ancestor.get("Name");
            }
            return null;
        },
    });
    var Buckets = BaseCollection.extend({
        model: Bucket,
        url: "bucket",
        refresh: function(){
            this.fetch({wait: true})
            console.log("Fetch")
        },
    });

    var Account = Bucket.extend({});
    var Accounts = BaseCollection.extend({
        model: Account,
        url: "account",
    });

    var Transaction = BaseModel.extend({
        defaults: function(){
            return {
                ID: null,
                Status: 0,
                TransDate: null,
                PostDate: null,
                Amount: 0,
                SourceBucket: -1,
                DestBucket: -1,
                Memo: "",
                Payee: "",
                GroupID: -1,
            };
        },
    });
    var Transactions = BaseCollection.extend({
        model: Transaction,
        url: "transaction",
        initialize: function(){
            this.listenTo(this, "update", this.update);
        },
    });

    var TransactionGroup = BaseModel.extend({
        getTransactions: function(){
            //TODO: Hardcoded group ID for scaffolding
            return transactions.where({Group: -1});
        },
        defaults: function(){
            return {
                ID: null,
                Bucket: null,
                Memo: "",
            };
        },
        renderTR: function(){
            var self = this;

            if(this.parentView.tableName == "transactionGroupTable"){
                BaseModel.prototype.renderTR.apply(this);
                return;
            }


            var model = this.getModel();
            if(model){
                this.$el.empty(); //TODO: Rather than replacing the row, we should change the existing one

                this.$el.attr("data-toggle", "collapse");
                this.$el.attr("data-target", ".group" + model.get("ID"))

                this.$el.text(JSON.stringify(model.toJSON()))
            }
        },
    });
    var TransactionGroups = BaseCollection.extend({
        model: TransactionGroup,
        url: "transaction-group",
        initialize: function(){
            //this.listenTo(this, "update", this.update);
        },
    });

    var MergedCollection = Backbone.Collection.extend({
        initialize: function(collections){
            var self = this;

            var onEvent = function(eventName, arg1, arg2, arg3){
                self.trigger(eventName, arg1, arg2, arg3)
            };

            collections.forEach(function(item, index){
                self.listenTo(item, "all", onEvent);
            });

            this.collections = collections;
        },
        get: function(id){
            var result = this.collections.forEach(function(item, index){
                var model = item.get(id);
                if(model){
                    return model;
                }
            });
            return result;
        },
        where: function(attributes){
            var models = [];
            this.collections.forEach(function(item, index){
                var res = item.where(attributes);
                models.push(res);
            });
            return _.union(...models);
        },
    });

    // Create instances of the model collections
    var accounts = new Accounts;
    var buckets = new Buckets;
    var transactions = new Transactions;
    var transactionGroups = new TransactionGroups;
    var accountBuckets = new MergedCollection([accounts, buckets]);

    // Base Views
    var BaseModelView = Object.create(null);
    BaseModelView.model = null;
    BaseModelView.setModel = function(newModel){
        if(this.model){
            this.model.stopListening()
        }
        this.model = newModel;
        this.trigger("modelChanged", newModel);
    };
    BaseModelView.getModel = function(){
        return this.model || null;
    };
    BaseModelView.getModelConstructor = function(){
        return this.constructor || null;
    };

    var ViewContainer = Backbone.View.extend({
        views: null,
        initialize: function(element){
            this.views = [];
            this.setElement(element);
        },
        render: function(){
            var self = this;
            console.log("ViewContainer.render");
            this.$el.empty(); // TODO: I don't like the erase and reset model, fix it
            this.views.forEach(function(item){
                item.render();
                self.$el.append(item.$el);
            })
        },
        addView: function(view){
            this.views.push(view);
        },

    });
    var TriggerButton = Backbone.View.extend({
        initialize: function(item, preClick){
            if(item){
                this.setElement(item);
            }
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

    //TODO: SelectView is broken; It is intended to be instanced rather than extended for "simple" selects
    var SelectView = Backbone.View.extend({
        events: {
            "change" : "onChange",
        },
        initialize: function(args){
            this.setElement($("<select>"));
            this.initUnselected = getOrDefault(args, "initUnselected", false);
            this.noSelection = getOrDefault(args, "noSelection", null);// {text: "N/A", value: -1}
            this.nameFormatter = getOrDefault(args, "formatter", null);
            this.options = [{text: "No Options", value: 0, selected: true, defaultSelected: true}];
        },
        render: function(){
            console.log("SelectView.render")
            var lastState =  this.$el.prop("disabled");
            this.$el.prop("disabled", true);

            this.$el[0].options.length=0

            var value = -1; // TODO: this is a placeholder
            if(this.noSelection){
                this.$el[0].options.add(new Option(this.noSelection.text, this.noSelection.value, true, (this.noSelection.value == value)));
            }

            var self = this;
            this._getOptions().forEach(function(item, index){
                self.$el[0].options.add(new Option(item.text, item.value, item.defaultSelected, item.selected));
            });

            this.$el.prop("disabled", lastState);

            this.$el.change();
        },
        _getOptions: function(){
            return this.options;
        },
        onChange: function(data){console.log("Warning: SelectView.onChange is uninitialized!")},
    });
    var DynamicSelectView = SelectView.extend({
        initialize: function(args){
            SelectView.prototype.initialize.apply(this, args);
            this.on("modelChanged", this.modelChanged, this)
        },
        _getOptions: function(){
            var value = -1; //TODO: Placeholder
            var options = [];
            var self = this;
            if(this.getModel()){
                this.getModel().where().forEach(function(ite, ind){
                    //TODO: Not all models this can handle will have a name field; Fix it
                    var text = ite.get("Name");
                    if(self.nameFormatter){
                        text = self.nameFormatter(ite);
                    }
                    options.push({text: text, value: ite.get("ID"), defaultSelected: false, selected: (value == ite.get("ID"))});
                });
            }
            return options;
        },
        modelChanged: function(newModel){
            //TODO: this.listenTo(newModel, "add", this.render)
            //TODO: this.listenTo(newModel, "remove", this.render)
            this.listenTo(newModel, "update", this.render)
            this.listenTo(newModel, "reset", this.render)
            this.listenTo(newModel, "sort", this.render)
            this.listenTo(newModel, "change:Name", this.render) //TODO: Inefficient
            //TODO: this.listenTo(newModel, "request", this.render)
            //TODO: this.listenTo(newModel, "sync", this.render)
            this.render();
        },
    }).extend(BaseModelView);
    var TableRowView = Backbone.View.extend({
        initialize: function(rowRenderer, parentView){
            this.setElement($("<tr>"));
            this.parentView = parentView;

            if(rowRenderer){
                this.render = rowRenderer;
            }

            this.listenTo(this, "modelChanged", function(newModel){
                this.listenTo(newModel, "change", this.render) //TODO: Inefficient
                this.listenTo(newModel, "destroy", this.render)

                //TODO: This is a quick fix
                // Watch the models of my source and dest bucket for name changes
                var source = (newModel.get("SourceBucket") != -1 ? accountBuckets.where({ID: newModel.get("SourceBucket")}) : []);
                var dest = (newModel.get("DestBucket") != -1 ? accountBuckets.where({ID: newModel.get("DestBucket")}) : []);

                if (source.length > 0){
                    this.listenTo(source[0], "change:Name", this.render)
                }

                if (dest.length > 0){
                    this.listenTo(dest[0], "change:Name", this.render)
                }

                this.render();
            });
        },
        render: function(){
            console.log("Warning: Row renderer is uninitialized!");
            this.$el.text("Row renderer is uninitialized")
        },
        _createActionButtons: function(buttons){
            var div = $("<div>").attr("role", "group").attr("class", "btn-group");
            buttons.forEach(function(item, index){
                var button = createTriggerButton(item);
                div.append(button.$el);
            });
            return div;
        },
    }).extend(BaseModelView);
    var TableToolBar = ViewContainer.extend({
        initialize: function(table, toolbarName){
            ViewContainer.prototype.initialize.apply(this, $("#" + toolbarName));
            this.table = table;
        },
        addTriggerButton: function(button){
            var button = createTriggerButton(button);
            this.addView(button);
        },
    });

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
		    console.log("Render: BaseModal");
		    if (this.title == undefined){
				this.title = "No Title";
			}
			this.$el.find(".modal-title").text(this.title)
		},
		triggers: [],
    });
    var BaseForm = Backbone.View.extend({
        formName: null,
        initialize: function(){
            if(this.formName == null || this.formName == undefined){
			    console.log("BaseForm.initialize: invalid formName!!")
			}

			var formDiv = $("#" + this.formName + "Div");
            var form = this.generateForm(formDiv);
            formDiv.append(form);
            this.setElement(form);

            this.on("modelChanged", this.render);
        },
        generateForm: function(){
            var cols = []
            var self = this;

            var listeners = {};
            var inputs = [];
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
                        case "dynamicSelect":
                            var dynamicSelect = new DynamicSelectView;
                            input = dynamicSelect.$el;

                            if ((item.options ? getOrDefault(item.options, "showNA", false) : false)){
                                dynamicSelect.noSelection = {text: "N/A", value: -1};
                            }

                            if ((item.options ? getOrDefault(item.options, "formatter", false) : false)){
                                dynamicSelect.nameFormatter = item.options.formatter;
                            }

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

                        if (item.options){
                            var value = getOrDefault(item.options, "listenTo", null);
                            if(value != null){
                                Object.keys(value).forEach(function(key, index){
                                    var array = listeners[key];
                                    if(!array){
                                        array = {};
                                        listeners[key] = array;
                                    }
                                    array[item.name] = value[key];
                                });
                            }
                        }
                        inputs[item.name] = input;

                        div.append(input);
                        cols.push(div);
                    }
                }
            });

            Object.keys(listeners).forEach(function(triggerName, index){
                var listenList = listeners[triggerName];
                Object.keys(listenList).forEach(function(listenName, index2){
                    var handlerFunction = listenList[listenName];
                    inputs[triggerName].change({self: inputs[listenName]}, handlerFunction);
                });
            });

            var form = $("<form></form>");
            form.attr("name", this.formName);
            cols.forEach(function(item, index){
                form.append(item);
            });
            return form;
        },
        render: function(){
            console.log("Render: BaseForm");
			var data = (this.getModel() ?  this.getModel().toJSON() : {});
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

				$(item).change();
			});
		},
		submit: function(){
		    //alert("Form Submit!!");
            var data = this.$el.serializeArray()

            // Call the submit callback for the affected table
            console.log("Form Data: " + JSON.stringify(data))
            var isValid = this.validate(data);

            if (isValid){
                this.trigger("formSubmit", data, this.getModel());
            }

            // We return false to prevent the web page from being reloaded
            return false;
        },
        validate: function(data){return true},
        columns: [],
    }).extend(BaseModelView);
    var BaseFormModal = BaseModal.extend({
        initialize: function(){
            BaseModal.prototype.initialize.apply(this);
            // Create the modal buttons in the footer for the form
            var submitBtn = $('<button/>').attr({type: 'submit', class: 'btn btn-default btn-primary'});
            submitBtn.text('Submit');
            this.submitBtn = new TriggerButton(submitBtn);
            this.$el.find(".modal-footer").append(submitBtn)
        },
        bindSubmitToForm: function(form){
            form.listenTo(this.submitBtn, "buttonClick", form.submit);
        },
    });
    var BaseTableView = Backbone.View.extend({
        model: null,
        apiDataType: null,
        initialize: function(actionModals){
        	console.log("BaseTableView.initialize: " + this.tableName);
        	this.setElement($("#" + this.tableName))

            var self = this;

            this.loadData = function(){
                self.$el.jsGrid("loadData");
            };

            //TODO: this.listenTo(this.model, "add", this.loadData);
            //TODO: this.listenTo(this.model, "remove", this.loadData);
            this.listenTo(this.model, "update", this.loadData);
            this.listenTo(this.model, "reset", this.loadData);
            //TODO: this.listenTo(this.model, "request", );
            //TODO: this.listenTo(this.model, "sync", );
            this.listenTo(this.model, "sort", this.loadData)

            // Initialize the enum formatters
            this.columns.forEach(function(item, index){
                if(getOrDefault(item, "type", "text") == "enum"){
                    var enumKey = (item.options ? getOrDefault(item.options, "enumKey", null) : null);
                    if(enumKey != null){
                        var optionsArray = getOrDefault(enums, enumKey, ["Invalid enum: " + enumKey]);
                        item.type = "text";
                        self.formatters[item.name] = function(value, rowData){
                            return {
                                text: optionsArray[value],
                            };
                        };
                    }
                }
            });

            var table = this.$el.jsGrid({
                autoload: false,
                controller: self.getController(),

                width: "100%",
                height: "auto",

                heading: true,
                filtering: false,
                inserting: false,
                editing: false,
                selecting: true,
                sorting: true,
                paging: false,
                pageLoading: false,

                rowClass: function(item, itemIndex) {}, //TODO: Use this to implement row color based on status
                rowClick: function(data){}, // This must be empty

                noDataContent: "No Data",

                confirmDeleting: false, // Disable the builtin delete confirm because we have our own

                loadIndication: true,
                loadIndicationDelay: 100,
                loadMessage: "Please, wait...",
                loadShading: true,

                updateOnResize: true,

                rowRenderer: self.getRowRenderer(actionModals),
                headerRowRenderer: self.getHeaderRowRenderer(actionModals),

                onInit: function(args){
                    console.log("Initialized Table: " + self.tableName);
                }
            });
        },
        getController: function(){
            var self = this;
            return {
                loadData: function (filter){
                    return new Promise(function(resolve, reject){
                        var result = [];
                        //result = self.model.toJSON();
                        result = self.model.where();
                        resolve(result);
                    });
                },
            }
        },
        getRowRenderer: function(actionModals){
            var self = this; // this = The Current Table View
            var renderer = function(item, index){
                // this = The function caller, (The jsGrid instance)

                //TODO: Quick fix; eventually the TableRowView should be given the model directly
                var rowRenderFunction = getOrDefault(item, "renderTR", null);
                if(!(rowRenderFunction instanceof Function)){
                    console.log("%cWarning: Supplied row render function was not a function!", 'background: #222; color: #bada55');
                }

                var row = new TableRowView(rowRenderFunction, self);
                row.buttons = []; // Init the buttons array before we set to model because
                // setting the model triggers a render event and the code that is run expects the array to exist

                if (actionModals["edit"]){
                    var editPreClick = function(){
                        actionModals["edit"].modal.setTitle("Edit " + self.apiDataType)
                        actionModals["edit"].form.setModel(row.getModel());
                    };
                    row.buttons.push({
                        name: "edit",
                        cssClass: "fa fa-edit",
                        preClick: editPreClick,
                        listeners: [{listener: actionModals["edit"].modal, callback: actionModals["edit"].modal.showModal}],
                    });
                }

                if (actionModals["delete"]){
                    var deletePreClick = function(){
                        actionModals["delete"].modal.setTitle("Delete " + self.apiDataType)
                        actionModals["delete"].form.setModel(row.getModel());
                        actionModals["delete"].form.setMessage(JSON.stringify(row.getModel().toJSON()));
                        actionModals["delete"].form.setConfirmCallback(function(allClear){
                            if(allClear){
                                actionModals["delete"].form.getModel().destroy({wait: true});
                            }
                        });
                    };
                    row.buttons.push({
                        name: "delete",
                        cssClass: "fa fa-trash",
                        preClick: deletePreClick,
                        listeners: [{listener: actionModals["delete"].modal, callback: actionModals["delete"].modal.showModal}],
                    });
                }

                row.setModel(item);
                return row.$el;
            };
            return renderer;
        },
        getHeaderRowRenderer: function(actionModals){
            var self = this;

            var renderRow = function(){
                var rowSelf = this;
                this.$el.empty(); //TODO: Rather than replacing the row, we should change the existing one
                self.columns.forEach(function(item, index){
                    if(!(item.visible == false)){
                        rowSelf.$el.append($("<td>").text(item.title).attr("class", "responsive-hidden"));
                    }
                });

                //TODO: We need some way of knowing whether our rows have action buttons so we can know if we need to add a blank column for them
                //var div = self._createActionButtons(this.buttons)
                //this.$el.append($("<td>").append(div));
            }

            var renderer = function(item, index){
                var row = new TableRowView(renderRow);

                //Note for the future: if we ever want action buttons in the header
                // init them here
                row.buttons = []
                // look at getRowRenderer for an example

                row.render();
                return row.$el;
            };
            return renderer;
        },
        formatters: {},
        columns: [],
    });
    var BaseTableEditForm = BaseForm.extend({
        //validate: ....
    });

    // Utility Views
    var ConfirmActionModal = BaseModal.extend({
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
		    console.log("Render: ConfirmActionModal");
			$("#confirmActionModalText").text(this.message)
		}
    }).extend(BaseModelView);

    // Account Views
    var AccountTreeView = Backbone.View.extend({
        el: $("#accountTree"),
        _waitingList_: {},
        initialize: function(){
            this.$el.jstree({
                core: {
                    check_callback: true,
                    animation: false,
                    themes: {
                        name: "proton",
                        responsive: true,
                    },
                },
                conditionalselect : function (node, event) {
                    // TODO: A slightly more robust condition is better as the trans table is not the only table affected by this option
                    if(!getTableData("transactionTable").isLocked()){
                        return true;
                    }
                    console.log("Prevented changing the account selection")
                    return false;
                },
                plugins: [
                    //"checkbox",
                    //"contextmenu",
                    //"dnd",
                    //"massload",
                    //"search",
                    "sort",
                    //"state",
                    //"types",
                    "unique",
                    "wholerow",
                    //"changed",
                    //"conditionalselect",
                    //"grid"
                ],
                /*grid: {
                    width: "100%",
                    columns: [{
                        tree: true,
                        header: "Accounts"
                    }, {
                        tree: false,
                        header: "Balance",
                        value: "balance"
                    }],
                },*/
            });

            this.$el.on("select_node.jstree", this.nodeSelected)

            this.listenTo(accounts, "add", this.nodeAdded)
            this.listenTo(accounts, "remove", this.nodeRemoved)
            //TODO: this.listenTo(accounts, "update", )
            //TODO: this.listenTo(accounts, "reset", )
            this.listenTo(accounts, "change:Name", this.nodeChanged)
            this.listenTo(accounts, "change:Balance", this.nodeChanged)

            this.listenTo(buckets, "add", this.nodeAdded)
            this.listenTo(buckets, "remove", this.nodeRemoved)
            //TODO: this.listenTo(buckets, "update", )
            //TODO: this.listenTo(buckets, "reset", )
            this.listenTo(buckets, "change:Name", this.nodeChanged)
            this.listenTo(buckets, "change:Balance", this.nodeChanged)

            //TODO: this.listenTo(accounts, "sync", this.treeReset);
            //TODO: this.listenTo(buckets, "sync", this.treeReset);
        },
        forceSelection: function(){
            // Get node for the last selected account
            var node = this.$el.jstree().get_node(uiState.get("selectedAccount"));

            if(!node){
                // The node doesn't exist...
                // so select the first node in the tree
                this.$el.jstree('select_node', 'ul > li:first');
            } else {
                // Select the last selected node
                this.$el.jstree().select_node(node, false, false);
            }
        },
        nodeAdded: function(model, collection, options){
            if(this.$el.jstree().get_node(model.get("ID"))){
                console.log("Warning: Attempted to add a node that already existed!!")
                return;
            }

            // Decide whether to add the node or wait for it's parent
            var addNode = false;
            if(model.get("Ancestor") == -1){
                addNode = true;
            }

            // Skip this check if the node is an Account
            var parentNode = null;
            if(!addNode){
                var node = this.$el.jstree().get_node(model.get("Parent"))

                // Debug print
                console.log("Matched parent " + model.get("Parent") + " to " + JSON.stringify(node))
                if(node != false){
                    addNode = true;
                    parentNode = node;
                }
            }

            // Carry out that decision
            if(addNode){
                var nodes = this.responseToTreeNode([model.toJSON()]);
                this.$el.jstree().create_node((parentNode != null ? parentNode.id : "#"), nodes[0]);

                // Check whether this node is the parent of any waiting nodes
                var list = this._waitingList_[model.get("ID")];
                if(list){
                    // If yes, then add the waiting nodes too
                    var self = this;
                    list.forEach(function(item, index){

                        // We can safely assume that all ID's in the waiting list belong to Buckets
                        // since Accounts are never on the waiting list because they have no parent to wait for.
                        var model = buckets.get(item);
                        if(model){ // The model should never be undefined, but just in case; we will quietly fail.
                            var nodes = self.responseToTreeNode([model.toJSON()]);
                            self.$el.jstree().create_node(model.get("Parent"), nodes[0]);
                        }
                    });
                }
            } else {
                // Add the node to the waiting list
                var list = this._waitingList_[model.get("Parent")];
                if(!list){ // Lazy init the list
                    list = [];
                    this._waitingList_[model.get("Parent")] = list;
                }
                list.push(model.get("ID"));
            }

            this.forceSelection();
        },
        nodeRemoved: function(model, collection, options){
            var node = this.$el.jstree().get_node(model.get("ID"))
            this.$el.jstree().delete_node(node)

            this.forceSelection();
        },
        nodeChanged: function(model, value, options){
            var node = this.$el.jstree().get_node(model.get("ID"))
            this.$el.jstree().rename_node(node, this.getNodeText(model.toJSON()))

            this.forceSelection();
        },
        nodeSelected: function(node, selected, event){
            uiState.set("selectedAccount", parseInt(selected.node.id))
        },
        treeReset(model, response, options){

        },
        responseToTreeNode(data){
            var results = []
            var self = this;
            data.forEach(function(item, index) {
                results.push({"id": item.ID, "text": self.getNodeText(item)})
            });
            return results
        },
        getNodeText(model){
            var badgeClasses = "badge badge-pill float-right " + (parseInt(model.Balance) < 0 ? "badge-danger" : "badge-dark");
            return $("<span>").text(model.Name)[0].outerHTML + $("<span>").attr("class", badgeClasses).text(model.Balance)[0].outerHTML;
        },
    });
    var AccountStatusView = Backbone.View.extend({
        el: $("#accountStatusText"),
        initialize: function(){
            this.listenTo(uiState, "change:selectedAccount", function(model, selectedAccountID, options){
                var models = findModelsWhere([accounts, buckets], {ID: selectedAccountID});
                if(models && models.length > 0){
                    this.setModel(models[0]);
                }
            });

            this.listenTo(this, "modelChanged", function(newModel){
                this.listenTo(newModel, "change:Balance", this.render);
                this.listenTo(newModel, "change:PostedBalance", this.render);
                this.render();
            })
        },
        render: function(){
            console.log("Render: AccountStatusView")
        	if (this.getModel() != null) {
        	    this.$el.text("Available: \$" + this.getModel().get("Balance") + ", Posted: \$" + this.getModel().get("PostedBalance"));
        	    return;
            }
            this.$el.text("Error: model is null");
        },
    }).extend(BaseModelView);

    // Table Views
    var TransactionTable = BaseTableView.extend({
        model: transactions,
        tableName: "transactionTable",
        apiDataType: "transaction",
        initialize: function(actionModals){
            BaseTableView.prototype.initialize.apply(this, [actionModals]);
            this.listenTo(uiState, "change:selectedAccount", this.loadData); //TODO: ??

            this.knownGroupIDs = [-1]; // We include -1 here to make it as if that id has already been processed, causing it to be ignored
            this.lastGroupID = -1;
        },
        formatters: {
            "Type": function(value, rowData){
                var fromToStr = "";
                if (value == 0){//Transfer
                    fromToStr = (this.getTransferDirection(rowData, uiState.get("selectedAccount")) ? " from " : " to ");
                } else { // Other
                    fromToStr = (value == 2 ? " from " : " to ")
                }
                return {
                    text: enums["transactionType"][value] + fromToStr,
                };
            },
            "Amount": function(value, rowData){
                var isDeposit = this.getTransferDirection(rowData, uiState.get("selectedAccount"));
                return {
                    text: formatter.format(value * (isDeposit ? 1 : -1)),
                    class: (isDeposit ? "" : "text-danger"),
                };
            },
            "Bucket": function(value, rowData){
                var id = -2; //This value will cause the name func to return "Invalid ID"

                var transType = rowData.Type;
                var isDeposit = this.getTransferDirection(rowData, uiState.get("selectedAccount"));
                if(transType != 0){
                    id = (transType == 1 ? rowData.DestBucket : rowData.SourceBucket);
                } else {
                    id = (isDeposit ? rowData.SourceBucket : rowData.DestBucket);
                }

                return {
                    text: getBucketNameForID(accounts, buckets, id),
                };
            },
            "TransDate": function(value, rowData){
                var text = value;

                /*label: //TODO: This code needs reimplemented; Feature [3]
                if(rowData.PostDate && rowData.PostDate.toDate){
                    var d = new Date(1971,01,01);
                    if(rowData.PostDate.toDate() < d){
                        text = "N/A";
                        break label;
                    }
                    text = rowData.PostDate.format("YYYY-MM-DD");
                }*/
                return {
                    text: text,
                };
            },
        },
        columns: [
            {name: "ID", visible: false},
            {name: "Status", title: "Status", type: "enum", breakpoints:"xs sm md", options: {enumKey: "transactionStatus"}, responsive: {hide: false}},
            {name: "TransDate", title: "Date", type: "date", breakpoints:"xs", options: {formatString:"YYYY-MM-DD"}, responsive: {hide: false}},
            {name: "PostDate", title: "Posted", type: "date", breakpoints:"xs sm md", options: {formatString:"YYYY-MM-DD"}, responsive: {hide: true}},
            {name: "Amount", title: "Amount", type: "number", breakpoints:"", responsive: {hide: false}},
            {name: "Type", title: "Type", type: "text", breakpoints:"xs sm md", responsive: {hide: true}},
            {name: "Bucket", title: "Bucket", type: "text", breakpoints:"xs sm md", responsive: {hide: false}},
            {name: "Memo", title: "Memo", type: "text", breakpoints:"", responsive: {hide: false}},
            {name: "Payee", title: "Payee", type: "text", breakpoints:"xs sm", responsive: {hide: true}},
            {name: "GroupID", title: "Group", type: "number", breakpoints:"xs sm", responsive: {hide: false}},
        ],
        getController: function(){
            var self = this;
            var def = BaseTableView.prototype.getController.apply(this);

            def.loadData = function (filter){
                var selID = uiState.get("selectedAccount");

                if(selID != null && selID > -1){
                    return new Promise(function(resolve, reject){
                        var result = [];
                        var a = transactions.filter(function(data) {
                            var testResult = parseInt(data.get("SourceBucket")) == selID || parseInt(data.get("DestBucket")) == selID;
                            //console.log("Sort: " + testResult + " " + data.get("Amount"))
                            return testResult;
                        })
                        a.forEach(function(item, index){
                            result.push(item/*.toJSON()*/);
                        });

                        var b = transactionGroups.filter(function(data){
                            var testResult = parseInt(data.get("Bucket")) == selID;
                            //console.log("Sort: " + testResult + " " + data.get("Amount"))
                            return testResult;
                        })
                        b.forEach(function(item, index){
                            result.push(item/*.toJSON()*/);
                        });

                        resolve(result);
                    });
                }
            }
            return def;
        },
        /*getRowRenderFunction: function(table){
            var renderSwitcher = function(){
                var groupID = model.get("GroupID");
                if(groupID != this.lastGroupID){
                    if(!this.knownGroupIDs.includes(groupID)){
                        this.knownGroupIDs.append(groupID);
                        return renderHeaderRow;
                    }
                }

                // this = The row view
                var model = this.getModel();
                if(model){
                    this.$el.empty(); //TODO: Rather than replacing the row, we should change the existing one
                    console.log("TableRowView.render (group header): " + table.apiDataType + ", ID: " + model.get("ID"))
                    var rowSelf = this;
                    this.$el.text("Test " + groupID);
                }
            };

            return BaseTableView.prototype.getRowRenderFunction(table);
        },*/
    });
    var TransactionGroupTable = BaseTableView.extend({
        model: transactionGroups,
        tableName: "transactionGroupTable",
        apiDataType: "transaction-group",
        initialize: function(actionModals){
            BaseTableView.prototype.initialize.apply(this, [actionModals]);
        },
        columns: [
            {name: "ID", visible: false},
            {name: "Bucket", title: "Bucket", type: "text", breakpoints:"xs sm md", responsive: {hide: false}},
            {name: "Memo", title: "Memo", type: "text", breakpoints:"", responsive: {hide: false}},
        ],
    });
    var BucketTable = BaseTableView.extend({
        model: buckets,
        modalName: "bucketTableModal",
        tableName: "bucketTable",
        apiDataType: "bucket",
        initialize: function(actionModals){
            BaseTableView.prototype.initialize.apply(this, [actionModals]);
            this.listenTo(uiState, "change:bucketModalSelectedAccount", this.loadData);
        },
        formatters: {
            "Parent": function(value, rowData){
                return {
                    text: getBucketNameForID(accounts, buckets, value),
                };
            },
        },
        columns: [
            {name: "ID", visible: false},
            {name: "Name", title: "Name", type: "text", responsive: {hide: false}},
            {name: "Parent", title: "Parent", type: "text", responsive: {hide: false}}
        ],
        getController: function(){
            var self = this;
            var def = BaseTableView.prototype.getController.apply(this);
            def.loadData = function (filter){
                var selID = uiState.get("bucketModalSelectedAccount");
                if(selID != null && selID > -1){
                    return new Promise(function(resolve, reject){
                        var result = [];
                        var a = self.model.where({Ancestor: selID})
                        a.forEach(function(item, index){
                            result.push(item/*.toJSON()*/);
                        });
                        resolve(result);
                    });
                }
            }
            return def;
        },
    });
    var AccountTable = BaseTableView.extend({
        model: accounts,
        tableName: "accountTable",
        apiDataType: "account",
        columns: [
            {name: "ID", visible: false},
            {name: "Name", title: "Name", type: "text", responsive: {hide: false}}
        ],
    });

    // Form Views
    var onStatusChange = function(data){
        //TODO: these are magic numbers. use variable names instead
        var self = data.data.self;
        switch(parseInt(data.target.value)){
            case 4:
            case 5:
                self.attr("required", true);
                break;
            default:
                self.attr("required", false);
        }
    };

    var onTypeChange = function(data){
        var visible = false;
        var self = data.data.self;
        var flipFlop = (self.attr("name") == "SourceBucket");
        switch(parseInt(data.target.value)){
            case 0:
                visible = true;
                break;
            case 1:
                visible = !flipFlop
                break;
            case 2:
                visible = flipFlop;
                break;
        }
        self.prop("disabled", !visible);

        if(!visible){
            self.val(-1);
        }
    };

    var bucketNameFormatter = function(model){
        var text = model.get("Name");

        var ancestor = model.getAncestorName();
        if(ancestor != null){
            text = text + " (" + ancestor + ")";
        }
        return text;
    }

    var byIDFormatter = function(model){
        return "" + model.get("ID");
    }

    var TransactionTableEditForm = BaseTableEditForm.extend({
        formName: "transactionTableEditForm",
        tableName: "transactionTable",
        columns: [
            {name: "ID", visible: false},
            {name: "Status", title: "Status", type: "select", required: true, options: {enumKey: "transactionStatus"}},
            {name: "TransDate", title: "Date", type: "date", required: true},
            {name: "PostDate", title: "Posted", type: "date", options: {listenTo: {"Status": onStatusChange}}},
            {name: "Amount", title: "Amount", type: "number", options: {step: 0.01}},
            {name: "Type", title: "Type", type: "select", required: true, options: {enumKey: "transactionType"}},
            {title: "Source", name: "SourceBucket", required: true, type: "dynamicSelect", options: {showNA: true, model: accountBuckets, formatter: bucketNameFormatter, listenTo: {"Type": onTypeChange}}},
            {title: "Destination", name: "DestBucket", required: true, type: "dynamicSelect", options: {showNA: true, model: accountBuckets, formatter: bucketNameFormatter, listenTo: {"Type": onTypeChange}}},
            {name: "Memo", title: "Memo", type: "textbox"},
            {name: "Payee", title: "Payee", type: "text"},
            {title: "Transaction Group", name: "GroupID", required: true, type: "dynamicSelect", options: {showNA: true, model: transactionGroups, formatter: byIDFormatter/*, listenTo: {"Type": onTypeChange}*/}},
        ]
    });
    var TransactionGroupTableEditForm = BaseTableEditForm.extend({
        formName: "transactionGroupTableEditForm",
        tableName: "transactionGroupTable",
        columns: [
            {name: "ID", visible: false},
            {title: "Bucket", name: "Bucket", required: true, type: "dynamicSelect", options: {showNA: false, model: accountBuckets, formatter: bucketNameFormatter/*, listenTo: {"Type": onTypeChange}*/}},
            {name: "Memo", title: "Memo", type: "textbox"},
        ]
    });
    var BucketTableEditForm = BaseTableEditForm.extend({
        formName: "bucketTableEditForm",
        tableName: "bucketTable",
        columns: [
            {name: "ID", visible: false},
            {name: "Name", title: "Name", type: "text", required: true},
            {name: "Parent", title: "Parent", required: true, type: "dynamicSelect", options: {model: accountBuckets, formatter: bucketNameFormatter}}
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
    var BucketTableModal = BaseModal.extend({
        title: "Manage Accounts & Buckets",
        modalName: "bucketTableModal",
        triggers: [
            "#bucketTableModalToggle"
        ]
    });
    var TransactionGroupTableModal = BaseModal.extend({
        title: "Manage Transaction Groups",
        modalName: "transactionGroupTableModal",
        triggers: [
            "#transactionGroupTableModalToggle"
        ]
    });
    var AccountTableFormModal = BaseFormModal.extend({
        modalName: "accountTableEditFormModal",
    });
    var BucketTableFormModal = BaseFormModal.extend({
        modalName: "bucketTableEditFormModal",
    });
    var TransactionTableFormModal = BaseFormModal.extend({
        modalName: "transactionTableEditFormModal",
    });
    var TransactionGroupTableFormModal = BaseFormModal.extend({
        modalName: "transactionGroupTableEditFormModal",
    });

    // Other

    //TODO: Finish the filter modal
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
        initUnselected: false,
        onChange: function(data){
            var val = parseInt(this.$el.val());
            uiState.set("bucketModalSelectedAccount", val);
        },
    });
    var TableSortView = ViewContainer.extend({
        initialize: function(fieldNames, collection){
            ViewContainer.prototype.initialize.apply(this, $("<div>"))
            this.collection = collection;
            var FilterState = Backbone.Model.extend({
                defaults: function(){
                    return {
                        field: -1,
                        direction: -1,
                    }
                }
            })
            this.filterState = new FilterState;

            var self = this;
            var FieldSelect = SelectView.extend({
                onChange: function(data){
                    self.filterState.set(this.stateKey, this.$el.val())
                },
            });

            this.fieldSelect = new FieldSelect;
            this.fieldSelect.stateKey = "field";
            this.fieldSelect.options = arrayToSelectOptions(fieldNames);
            this.addView(this.fieldSelect);

            this.directionSelect = new FieldSelect;
            this.directionSelect.stateKey = "direction";
            this.directionSelect.options = arrayToSelectOptions(["Ascending", "Descending"]);
            this.addView(this.directionSelect);

            this.listenTo(this.filterState, "change", this.sortCollection)
        },
        sortCollection: function(){
            var state = this.filterState;
            var field = state.get("field");
            var direction = state.get("direction");

            var temp = _.findWhere(this.fieldSelect.options, {value: parseInt(field)});
            var fieldName = getOrDefault(temp, "text", "Error");

            console.log("Sorting by: " + fieldName + " " + direction)
            this.collection.sortKey = fieldName;
            this.collection.reverseSortDirection = (parseInt(direction) > 0)
            //TODO: Respect the sort direction
            this.collection.sort();
            var debugList = this.collection.pluck(fieldName);
            console.log(JSON.stringify(debugList));
        },
    });

    // Initialize the views in order of dependency
    var actionConfirmationModal = new ConfirmActionModal;
    var accountTree = new AccountTreeView;
    var accountStatusViewInst = new AccountStatusView;

    var transactionFilterModal = new TransactionTableFilterModal();
    var transactionEditForm = new TransactionTableEditForm;
    var transactionEditFormModal = new TransactionTableFormModal;
    var transactionTable = new TransactionTable({
        "edit" : {form: transactionEditForm, modal: transactionEditFormModal},
        "delete" : {form: actionConfirmationModal, modal: actionConfirmationModal},
    });
    transactionTable.listenTo(transactionGroups, "update", transactionTable.loadData);
    transactionTable.listenTo(transactionGroups, "reset", transactionTable.loadData);
    transactionTable.listenTo(transactionGroups, "sort", transactionTable.loadData);
    var transactionTableToolBar = new TableToolBar(transactionTable, "transactionTableEditToolbar");
    var transactionAddPreClick = function(){
        transactionEditFormModal.setTitle("New Transaction")
        transactionEditForm.setModel(null);
    };
    transactionTableToolBar.addTriggerButton({
        name: "new",
        cssClass: "fa fa-plus-circle",
        preClick: transactionAddPreClick,
        listeners: [{listener: transactionEditFormModal, callback: transactionEditFormModal.showModal}],
    }); // New
    transactionTableToolBar.addTriggerButton({
        name: "filter",
        cssClass: "fa fa-filter",
        listeners: [{listener: transactionFilterModal, callback: transactionFilterModal.showModal}],
    }); // Filters
    transactionTableToolBar.addView(new TableSortView(_.filter(_.pluck(transactionTable.columns, "name"), function(val){ return val }), transactions));
    transactionTableToolBar.render();
    var saveFunction = function(data, model){
        //TODO: Any empty values should be sent to the server as null or not at all

        // Perform updates to the model
        if(model == null){
            // We are creating a new table entry
            this.create(cleanData(data), {wait: true});
        } else {
            model.save(cleanData(data), {wait: true});
        }
    };
    transactionEditFormModal.bindSubmitToForm(transactionEditForm);
    transactions.listenTo(transactionEditForm, "formSubmit", saveFunction);
    transactionEditFormModal.listenTo(transactionEditForm, "formSubmit", transactionEditFormModal.hideModal)

    var transactionGroupTableModal = new TransactionGroupTableModal;
    var transactionGroupEditForm = new TransactionGroupTableEditForm;
    var transactionGroupEditFormModal = new TransactionGroupTableFormModal;
    var transactionGroupTable = new TransactionGroupTable({
        "edit" : {form: transactionGroupEditForm, modal: transactionGroupEditFormModal},
        "delete" : {form: actionConfirmationModal, modal: actionConfirmationModal},
    });
    var transactionGroupTableToolBar = new TableToolBar(transactionGroupTable, "transactionGroupTableEditToolbar");
    var transactionGroupAddPreClick = function(){
        transactionGroupEditFormModal.setTitle("New Transaction Group")
        transactionGroupEditForm.setModel(null);
    };
    transactionGroupTableToolBar.addTriggerButton({
        name: "new",
        cssClass: "fa fa-plus-circle",
        preClick: transactionGroupAddPreClick,
        listeners: [{listener: transactionGroupEditFormModal, callback: transactionGroupEditFormModal.showModal}],
    }); // New
    transactionGroupTableToolBar.addView(new TableSortView(_.filter(_.pluck(transactionGroupTable.columns, "name"), function(val){ return val }), transactionGroups));
    transactionGroupTableToolBar.render();
    transactionGroupEditFormModal.bindSubmitToForm(transactionGroupEditForm);
    transactionGroups.listenTo(transactionGroupEditForm, "formSubmit", saveFunction);
    transactionGroupEditFormModal.listenTo(transactionGroupEditForm, "formSubmit", transactionGroupEditFormModal.hideModal)

    var bucketTableModal = new BucketTableModal;
    var bucketTableAccountSelect = new BucketTableAccountSelect;
    var bucketEditForm = new BucketTableEditForm;
    var bucketEditFormModal = new BucketTableFormModal;
    var bucketTable = new BucketTable({
        "edit": {form: bucketEditForm, modal: bucketEditFormModal},
        "delete" : {form: actionConfirmationModal, modal: actionConfirmationModal},
    });
    var bucketTableToolBar = new TableToolBar(bucketTable, "bucketTableEditToolbar");
    var bucketAddPreClick = function(){
        bucketEditFormModal.setTitle("New Bucket")
        bucketEditForm.setModel(null);
    };
    bucketTableToolBar.addTriggerButton({
        name: "new",
        cssClass: "fa fa-plus-circle",
        preClick: bucketAddPreClick,
        listeners: [{listener: bucketEditFormModal, callback: bucketEditFormModal.showModal}],
    }); // New
    bucketTableToolBar.addView(bucketTableAccountSelect);
    bucketTableToolBar.addView(new TableSortView(_.filter(_.pluck(bucketTable.columns, "name"), function(val){ return val }), buckets));
    bucketTableToolBar.render();
    bucketTable.listenTo(bucketTableAccountSelect, "modelChanged", bucketTable.loadData)
    bucketEditFormModal.bindSubmitToForm(bucketEditForm);
    buckets.listenTo(bucketEditForm, "formSubmit", saveFunction);
    bucketEditFormModal.listenTo(bucketEditForm, "formSubmit", bucketEditFormModal.hideModal)

    var accountEditForm = new AccountTableEditForm;
    var accountEditFormModal = new AccountTableFormModal;
    var accountTable = new AccountTable({
        "edit": {form: accountEditForm, modal: accountEditFormModal},
        "delete" : {form: actionConfirmationModal, modal: actionConfirmationModal},
    });
    var accountTableToolBar = new TableToolBar(accountTable, "accountTableEditToolbar");
    var accountAddPreClick = function(){
        accountEditFormModal.setTitle("New Account")
        accountEditForm.setModel(null);
    };
    accountTableToolBar.addTriggerButton({
        name: "new",
        cssClass: "fa fa-plus-circle",
        preClick: accountAddPreClick,
        listeners: [{listener: accountEditFormModal, callback: accountEditFormModal.showModal}],
    }); // New
    accountTableToolBar.addView(new TableSortView(_.filter(_.pluck(accountTable.columns, "name"), function(val){ return val }), accounts));
    accountTableToolBar.render();
    accountEditFormModal.bindSubmitToForm(accountEditForm);
    accounts.listenTo(accountEditForm, "formSubmit", saveFunction);
    accountEditFormModal.listenTo(accountEditForm, "formSubmit", accountEditFormModal.hideModal)

    // Fetch the data from the server
    accounts.fetch({wait: true});
    buckets.fetch({wait: true});
    transactions.fetch({wait: true});
    transactionGroups.fetch({wait: true});

    bucketTableAccountSelect.setModel(accounts); // Init the bucket table account select

    var refreshBalanceFunction = function(){
        console.log("Refreshing Balance...");
        this.fetch({wait: true})
    }

    // TODO: These event listeners are a quick fix
    accounts.listenTo(transactions, "change", refreshBalanceFunction)
    buckets.listenTo(transactions, "change", refreshBalanceFunction)

    accounts.listenTo(transactions, "update", refreshBalanceFunction)
    buckets.listenTo(transactions, "update", refreshBalanceFunction)

    // Not this one though...
    $("#saveChanges").click(function(){
        var collections = {Accounts: accounts, Buckets: buckets, Transactions: transactions}

        Object.keys(collections).forEach(function(key, index){
            console.log("Saving " + key + ".....");
            collections[key].sync();
        });
    });
}