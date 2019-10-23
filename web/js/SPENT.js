var tables = {}
var tableSchema = {}
var enums = {}
var lastSelection = null;
var bucketNameMap = {}

// Create our number formatter.
var formatter = null;

// ############################## Utility Functions ##############################

function getOrDefault(object, property, def){
	return (object[property] != undefined ? object[property] : def);
}

function getTableData(tableName){
	var table = tables[tableName];
	if(!table){
		console.log("Table " + tableName + " was undefined")
	}
	return table;
}

function doesNodeHaveParent(node){
    return node.parentId != undefined;
}

function cleanRowData(data){
    // This converts objects of format [{name: ***, value: ***}, ..., ...]
    // to {The name: The value, The next name: The next value}
    var obj = {};

    // This loop style is used because "data" doesn't have .forEach or .length
    // for some reason
    for(var index = 0; data[index] != undefined; index++){
        obj[data[index].name] = data[index].value;
    }
    return obj;
}

function getTransferDirection(rowData, node){
	// True = Money Coming in; I.E. a positive value
	// False = Money Going out; I.E. a negative value
	switch(rowData.Type){
		case 0:
			return (rowData.DestBucket == node.dataAttr.ID);
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

function getBucketNameForID(id){
    var name = bucketNameMap[id];
    if(name == undefined){
        if(id == undefined){
            alert("What?")
        }
        return "Unknown ID: " + id;
    }
    return name;
}

function getTransactionFilterRules(){
    var result = $('#transactionTableFilter').queryBuilder('getRules');

    if ($.isEmptyObject(result)) {
        return null;
    }
    return result;
}

function getSelectedAccount() {
    var selected = $('#accountTree').treeview('getSelected');
	if (selected.length < 1) {
	    var nodes = $("#accountTree").treeview('getNodes');
	    $('#accountTree').treeview('selectNode', [ [nodes[0]], { silent: true } ]);
		selected = $('#accountTree').treeview('getSelected');
	}
	//TODO: This is a very quick fix for the badges not appearing right
    $(".node-accountTree .badge").attr("class", "badge badge-pill badge-secondary testClass float-right")
	return selected[0]
}

function getSelectedBucketTableAccount(){
    var selectedVal = $("#bucketEditAccountSelect :selected")
    if (selectedVal.val() == undefined){
        return {ID: -1, Name: "Error!"}
    }
    return {ID: parseInt(selectedVal.val()), Name: selectedVal.text()}
}

function getBucketOptions(){
	//TODO: Rewrite this to account for the selected account and whether the type is set as "transfer"
	var array = [];
	return apiRequest(createRequest("get", "account", null, ["ID", "Name", "Parent", "Ancestor"])).then(function(result){
		result.data.forEach(function(item, index){

			array.push({"ID": item.ID, "Name": item.Name})
		});
		return apiRequest(createRequest("get", "bucket", null, ["ID", "Name", "Parent", "Ancestor"]));
	}).then(function(result2){
		//alert("Hello World")

		result2.data.forEach(function(item, index){
			array.push({"ID": item.ID, "Name": item.Name + " (" + (item.Ancestor != -1 ? getBucketNameForID(item.Ancestor) : "")  + ")"})
		});

		return Promise.resolve(array);
	});
}

function getTypeOptions(){
	return enums["transactionTable"]["Type"];
}

function getStatusOptions(){
	return enums["transactionTable"]["Status"];
}


// ########################## #### API Logic ##############################

function apiRequest(requestObj, callback){
	return $.ajax({
		url: '/database/apiRequest',
		type: "POST",
		contentType: "application/json; charset=utf-8",
		dataType: "json",
		data: JSON.stringify(requestObj),
		success: function(data) {
		    if(apiRequestSuccessful(data)){
			   	if(callback){
				   callback(data);
				}
			}
			return data
		},
		error: function(data) {
			alert("Request Error!!\n" + JSON.stringify(data));
		}
	});
}

//TODO: The selAccount parameter is temperary until a proper API change for this type of data is designed
function createRequest(action, type, data, columns, rules, selAccount){
	//TODO: Verify the input data and sanitize it
	var request = {
		action: action,
		type: type
	}

	if(data != undefined && data != null){
	   request.data = data;
		if(data.length < 1){
			request.data = null;
		}
	}
	
	if(columns != undefined && columns != null){
	   request.columns = columns;
	   	if(columns.length < 1){
			request.columns = null;
		}
	}

	if(rules != undefined && rules != null){
	   request.rules = rules;
	   	if(rules.length < 1){
			request.rules = null;
		}
	}

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

function apiResponseToTreeView(response){
	var results = []
	var data = response.data;
	if (data != undefined) {
		results = responseToTreeNode(data);
	}

	if(results.length < 1){
	    results.push({"text": "No Accounts", "dataAttr": {"ID": -1, "childrenIDs": []}})
	}

	return results;
}

function responseToTreeNode(data){
	var results = []
	data.forEach(function(item, index) {
		var children = [];
		item.Children.forEach(function(it, ind){
			children.push({"id": it})
		});
		results.push({"text": item.Name, "lazyLoad": (item.Children.length > 0), dataAttr: {"childrenIDs": item.Children, "ID": item.ID}, "tags": [item.Balance]})
	});
	return results
}

function apiTableSchemaToColumns(tableName){
	var columns = []
	tableSchema[tableName].columns.forEach(function(item, index){
		var obj = {"name": (item.name ? item.name : item.title ), "title": item.title};

//Type: "text"|"number"|"checkbox"|"select"|"textarea"|"control" or custom type
//Width??

 /*   filtering: true,
    editing: true,
    sorting: true,
    sorter: "string", // See list of sorting strategies

    cellRenderer: null,  // Formatter replacement

    validate: null*/

        //obj.width = "1"
		if(item.visible != undefined){
		   obj.visible = item.visible
		}
		   
		/*if(item.breakpoints){
			obj.breakpoints = item.breakpoints;
		}*/
		
		/*if(item.formatString){
			obj.formatString = item.formatString;	
		}

		if(item.sortValue){
			obj.sortValue = item.sortValue;
		}*/
		
		if(item.formatter){
		    obj.cellRenderer = item.formatter
		}

		switch(item.type){
			case "enum":
				obj.type = "text"
				obj.cellRenderer = function(value, rowData){
					return '<td>' + enums[tableName][obj.name][value] + '</td>';
				};
				break;
			case "formatter":
				obj.type = "text"
				break;
			default:
				obj.type = item.type;
				break;
		}

		columns.push(obj);
	});
	return columns;
}

function apiTableSchemaToEditForm(tableName){
	var columns = []
	//alert("Edit Form for: " + tableName);
	tableSchema[tableName].columns.forEach(function(item, index){
		if(item.formVisible != false){
			var titleStr = (item.title ? item.title : item.name); 

			var div = $("<div class='form-group'></div>");
			div.append($('<label>' + titleStr + '</label>').attr('for', item.title));

			//formType, required, options, formVisible, formDynamicSelect

			var input = null;
			var typeStr = "text";
			
			switch(item.formType){
				default:
					var input = $('<input class="form-control" type="' + item.formType + '" value="' + "" + '" ' + (item.required ? " required " : "" ) + ' step="0.01" >');
					input.attr("name", item.name)
					div.append(input)
					break;
				case "select":
					var select = $("<select class='form-control'></select>")
					select.attr("name", item.name)
					select.attr("id", tableName + item.name)
					select.data("isDynamic", item.formDynamicSelect)
					select.data("optionFunc", item.options)
					
					if (!item.formDynamicSelect) {
						// If the option set is static
						var optionArray = select.data("optionFunc")();

						if(item.name == "Type"){
							var option = $('<option value="" selected disabled hidden>Select a transaction type</option>');
							select.append(option);
						}

						optionArray.forEach(function(item, index){
							var option = $('<option value="' + index + '">' + item + '</option>');
							select.append(option);
						});
					}

					//TODO: This is a quick fix;
					if(item.name == "Type"){
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
						   $("#" + tableName + "SourceBucket").prop("disabled", !sourceVisible);
						   $("#" + tableName + "DestBucket").prop("disabled", !destVisible);
						   
						   if(!sourceVisible){
							   $("#" + tableName + "SourceBucket").val(-1)
						   }
						   
						   if(!destVisible){
							   $("#" + tableName + "DestBucket").val(-1)
						   }
					   });
					}
					
					div.append(select)
					break;
			}
			columns.push(div);
		}
	});
	
	var form = $("<form id=\"" + tableName + "EditForm\" onsubmit='return onFormSubmit(this, \"" + tableName + "\")' method='GET'></form>")
	columns.forEach(function(item, index){
		form.append(item);
	});

	return form;
}

// ############################## GUI Control ##############################

function initTable(tableName, apiDataType){
	console.log("Initializing Table: " + tableName);
	tables[tableName] = {
		apiDataType: apiDataType,
		columns: apiTableSchemaToColumns(tableName),
		table: null,
		lockID: 0,
		lockTable: function(){
			// Do table locking
			this.table.isLocked = true;

			// Return the "key"
			this.lockID += 1;
			console.log("Locking " + tableName + " with key " + this.lockID)
			return this.lockID;
		},
		unlockTable: function(lockID){
			// Do table unlocking if id matches
			if(this.lockID == lockID){
				console.log("Unlocking " + tableName + " with key " + lockID)
				this.table.isLocked = false;
			} else {
				console.log("Error: Lock " + lockID + " attempted to unlock " + this.lockID + " on " + tableName)
			}
		},
		isLocked: function(lockID){
			var result = this.table.isLocked;
			if (lockID == this.lockID){
				console.log("Table " + tableName + " can be accessed by " + lockID);
				result = false;
			}

			console.log("Table " + tableName + " is " + (result ? "locked with key " + this.lockID : "not locked"))
			//return false;
			return result;
		},
		formCallback: function(tableRow, data){
		    if (tableRow){
		        $("#" + tableName).jsGrid("updateItem", tableRow, cleanRowData(data)).done(function() {
                    console.log("update completed");
                    refreshSidebarAccountSelect();
                    refreshBalanceDisplay();
                });
		    } else {
		        $("#" + tableName).jsGrid("insertItem", cleanRowData(data)).done(function() {
                    console.log("insert completed");
                    refreshSidebarAccountSelect();
                    refreshBalanceDisplay();
                });
		    }
			//TODO: make this actually reflect whether the callback completed sucessfully
			return true;
		},
		deleteCallback: function (tableRow){
		    $("#" + tableName).jsGrid("deleteItem", tableRow).done(function() {
                console.log("delete completed");
                refreshSidebarAccountSelect();
                refreshBalanceDisplay();
            });
		}
	};

    var fields = getTableData(tableName).columns;
    fields.push({
        type: "control",
        modeSwitchButton: false,
        editButton: true,
        headerTemplate: function() {
            var div = $("<div>").attr("role", "group").attr("class", "btn-group");

            var addBtn = $("<button>").attr("type", "button").attr("class", "btn").on("click", function () {
                showFormModal(tableName, null, "New Row");
            });
            addBtn.append($("<i>").attr("class", "fas fa-plus-circle"))
            div.append(addBtn);

            if(tableName == "transactionTable"){
                var filterBtn = $("<button>").attr("type", "button").attr("class", "btn").on("click", function () {
                    showModal("transactionTableFilterModal", null, "New Row");
                });
                filterBtn.append($("<i>").attr("class", "fas fa-filter"))
                div.append(filterBtn);
            }

            return div;
        },
        itemTemplate: function(a, b){
            var div = $("<div>").attr("role", "group").attr("class", "btn-group");

            var editBtn = $("<button>").attr("type", "button").attr("class", "btn").on("click", function (e) {
                e.stopPropagation();
                var row = $("#" + tableName).jsGrid('rowByItem', b)
                showFormModal(tableName, row, "Edit Row ID:" + row.data("JSGridItem").ID)
            });
            editBtn.append($("<i>").attr("class", "fas fa-edit"))
            div.append(editBtn);

            var deleteBtn = $("<button>").attr("type", "button").attr("class", "btn").on("click", function (e) {
                e.stopPropagation();
                var row = $("#" + tableName).jsGrid('rowByItem', b)
                showConfirmModal("Confirm Row Delete\n" + JSON.stringify(row.data("JSGridItem")), function(allClear){
                    if(allClear){
                        getTableData(tableName).deleteCallback(row);
                    }
                })
            });
            deleteBtn.append($("<i>").attr("class", "fas fa-trash"))
            div.append(deleteBtn);

            if(tableName == "transactionTable"){
                var tagBtn = $("<button>").attr("type", "button").attr("class", "btn").on("click", function (e) {
                    e.stopPropagation();
                    var row = $("#" + tableName).jsGrid('rowByItem', b)

                    //TODO: This should open a form modal, but the function currently assumes a table is associated with the form
                    //showModal("transactionTagEditorModal");
                    showFormModal("transactionTag", row, "Tags:" + row.data("JSGridItem").ID)
                });
                tagBtn.append($("<i>").attr("class", "fas fa-tags"))
                div.append(tagBtn);
            }

            return div;
        }
    })

    var table = $("#" + tableName).jsGrid({
        fields: fields,
        autoload: true,
        controller: {
            loadData: function (filter){
                var selID = (getTableData(tableName).apiDataType == "transaction" ? getSelectedAccount().dataAttr.ID : getSelectedBucketTableAccount().ID)

                var rules = null;
                if(getTableData(tableName).apiDataType == "transaction"){
                    rules = getTransactionFilterRules();
                }

                return apiRequest(createRequest("get", getTableData(tableName).apiDataType, null, null, rules, selID)).then(function(data){
                    return data.data;
                });
            },
            insertItem: function (data){
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
            }
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
		    onTableReady(tableName, args.grid);
	    }
    });

	// Create the row edit form
	var editForm = $("#" + tableName + "EditFormDiv");
	if(editForm){
		initTableEditForm(editForm, apiTableSchemaToEditForm(tableName), tableName);
	}
}

function initTableEditForm(editFormDiv, editForm, tableName){
    //alert("init Edit Form for: " + tableName);
	editFormDiv.append(editForm)

	// Create the modal buttons in the footer
	if (editFormDiv.data("submit")){
	    var submitBtn = $('<button/>').attr({type: 'submit', class: 'btn btn-default btn-primary'});
	    submitBtn.text('Submit')
	    submitBtn.click(function(){
            editForm.submit();
        })
	    $("#" + tableName + "EditFormModal" + " .modal-footer").append(submitBtn)
	}
}

function initFilterModal(){
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
}

function refreshSidebarAccountSelect(){
    //TODO: This is not my prefered way of making this work
    // but the treeview doesn't have a proper refresh function
    $("#accountTree").treeview(true).init($("#accountTree").treeview(true).options)
    $('#accountTree').on("nodeSelected", function(e, node) {
        onTreeSelection(e, node);
    });
}

function refreshBucketTableAccountSelect() {
	// Bucket Editor
	var select = $("#bucketEditAccountSelect");
	if(select.data("optionFunc") == undefined){
	    select.data("optionFunc", function(){
	        return apiRequest(createRequest("get", "account", null, ["ID", "Name"], null, null)).then(function(result){
	            var array = [];
                result.data.forEach(function(item, index){
                    array.push({"ID": item.ID, "Name": item.Name})
                });
                return Promise.resolve(array);
            })
	    })
	}

	updateDynamicInput(select, -1, select.data("optionFunc"))
}

function refreshBalanceDisplay() {
	if (getSelectedAccount() != undefined) {
		var node = getSelectedAccount();
		apiRequest(createRequest("get", (!doesNodeHaveParent(node) ? "account" : "bucket"), [{"ID": node.dataAttr.ID}], ["Balance", "PostedBalance"]), function(response) {
			$("#balanceDisplay").text("Available: \$" + response.data[0]["Balance"] + ", Posted: \$" + response.data[0]["PostedBalance"]);
		});
	} else {
		$("#balanceDisplay").text("Error fetching balance");
	}
}

function showFormModal(tableName, row, title){
	var data = (row ?  row.data("JSGridItem") : {});
	var form = $(updateFormContent(tableName + "EditForm", data, title))
	var inputs = form.find("select").toArray();
	inputs.forEach(function(item, index){
		var it = $(item)
		var needsUpdate = it.data("isDynamic");
		if(needsUpdate != undefined){
			if(needsUpdate()){
				rowVal = -1;
				if(row){
					rowVal = data[it[0].name];
				}
				updateDynamicInput(it, rowVal, it.data("optionFunc"));
			}
		}
	});
	form.data('row', row);
	form.data('rowID', data.ID);
	showModal(tableName + "EditFormModal");
}

function updateDynamicInput(it, value, optionFunction){
	it.prop("disabled", true);

	// After the function completes it shoud re-enable the input
	optionFunction().then(function(result){
		if(result == null){
			alert("Failed to update input: " + it)
		} else {
			it[0].options.length=0
			it[0].options.add(new Option("N/A", -1, true, (value == -1)));
			result.forEach(function(ite, ind){
				it[0].options.add(new Option(ite.Name, ite.ID, false, (value == ite.ID)))
			});
			
			if (it.attr('name') == "DestBucket" || it.attr('name') == "SourceBucket") {
				$("#transactionTableType").change();
			} else {
				it.prop("disabled", false);
			}
		}
	});
}

function populateBucketNameMap(data){
    data.data.forEach(function(item, index){
        bucketNameMap[item.ID] = item.Name;
    })
}

// ############################## Column Formatters ##############################

function transactionTypeFormatter(value, rowData){
	var fromToStr = "";
	if (value == "0"){//Transfer
		fromToStr = (getTransferDirection(rowData, getSelectedAccount()) ? " from " : " to ");
	} else { // Other
	    fromToStr = (value == "2" ? " from " : " to ")
	}
	return '<td>' + enums["transactionTable"]["Type"][value] + fromToStr + '</td>';
}

function transactionAmountFormatter(value, rowData){
	var isDeposit = getTransferDirection(rowData, getSelectedAccount());
	if (isDeposit){
		// If deposit
		return '<td>' + formatter.format(value) + '</td>';
	}
	return '<td>' + formatter.format(value * -1) + '</td>';
}

function bucketFormatter(value, rowData){
	return '<td>' + getBucketNameForID(value) + '</td>';
}

function transactionBucketFormatter(value, rowData){
	var id = -2; //This value will cause the name func to return "Invalid ID"

	var transType = rowData.Type;
	var isDeposit = getTransferDirection(rowData, getSelectedAccount());
	if(transType != 0){
		id = (transType == 1 ? rowData.DestBucket : rowData.SourceBucket);
	} else {
		id = (isDeposit ? rowData.SourceBucket : rowData.DestBucket);
	}

	//var par = getBucketParentForID(id);
	//if(par != -1){
	return '<td>' + getBucketNameForID(id) + '</td>';
	//} else {
		//rowData.bucketSort = "Unassigned";
	//}//
}

function transactionDateFormatter(value, rowData){
	if(rowData.PostDate.toDate){
		var d = new Date(1971,01,01);
		if(rowData.PostDate.toDate() < d){
			return "N/A";
		}
		return rowData.PostDate.format("YYYY-MM-DD");
	}
	return value;
}

// ############################## Event Handlers ##############################

function onDocumentReady() {
	// Undefined causes it to use the system local
	formatter = new Intl.NumberFormat(undefined, {
	  style: 'currency',
	  currency: 'USD',
	});

	bucketNameMap = {}

	tableSchema = {
		accountTable: {
			columns: [
				{name: "ID", visible: false, formVisible: false},
				{name: "Name", title: "Name", type: "text", required: true, formType: "text"}
			]
		},
		bucketTable: {
			columns: [
				{name: "ID", visible: false, formVisible: false},
				{name: "Name", title: "Name", type: "text", required: true, formType: "text"},
				{name: "Parent", title: "Parent", type: "formatter", formatter: bucketFormatter, required: true, formType: "select", options: getBucketOptions, formDynamicSelect: function(){ return true; }}
			]
		},
		transactionTable: {
			columns: [
				{name: "ID", visible: false, formVisible: false},
				{name: "Status", title: "Status", type: "enum", breakpoints:"xs sm md", formType: "select", options: getStatusOptions, required: true},
				{name: "TransDate", title: "Date", type: "date", breakpoints:"xs", formatString:"YYYY-MM-DD", required: true, formType: "date"},
				{name: "PostDate", title: "Posted", type: "date", breakpoints:"xs sm md", formatString:"YYYY-MM-DD", formType: "date"/*, formatter: transactionDateFormatter*/},
				{name: "Amount", title: "Amount", type: "formatter", breakpoints:"", required: true, formType: "number", formatterType: "number", formatter: transactionAmountFormatter},
				{name: "Type", title: "Type", type: "formatter", breakpoints:"xs sm md", required: true, formType: "select", options: getTypeOptions, formatter: transactionTypeFormatter},
				{title: "Bucket", type: "formatter", breakpoints:"xs sm md", formVisible: false, formatter: transactionBucketFormatter},
				{title: "Source", name: "SourceBucket", required: true, formType: "select", options: getBucketOptions, visible: false, formDynamicSelect: function(){ return true; }},
				{title: "Destination", name: "DestBucket", required: true, formType: "select", options: getBucketOptions, visible: false, formDynamicSelect: function(){ return true; }},
				{name: "Memo", title: "Memo", type: "text", breakpoints:"", formType: "textbox"},
				{name: "Payee", title: "Payee", type: "text", breakpoints:"xs sm", formType: "text"},
				{name: "Tags", title: "Tags", type: "text", breakpoints:"xs sm md", formVisible: true, formType: "text"},
			]
		}
	}

/*
title
breakpoints
required
options
formatter
type
formType
visible
formVisible
formDynamicSelect
*/

	enums = {
		transactionTable: {
			Status: [
				"Uninitiated",
				"Submitted",
				"Post-Pending",
				"Complete"
			],
			Type: [
				"Transfer", //0
				"Deposit", // 1
				"Withdrawal" //2
			]
		}
	}

	lastSelection = null;
	initFilterModal()

    // Create the transaction tag edit form
	var tagForm = $("#transactionTagEditFormDiv");
	if(tagForm){
	    var form = $("<form id=\"transactionTagEditForm\" onsubmit='return onFormSubmit(this, \"transactionTag\")' method='GET'></form>")

	    var div = $("<div class='form-group'></div>");
        div.append($('<label>Tags</label>').attr('for', "tags"));

        var input = $('<input class="form-control" type="text">');
        input.attr("name", "tags")
        div.append(input)

	    form.append(div)

		initTableEditForm(tagForm, form, "transactionTag");
	}


    /*conditionalselect : function (node, event) {
        // TODO: A slightly more robust condition is better as the trans table is not the only table affected by this option
        if(!getTableData("transactionTable").isLocked()){
            return true;
        }
        console.log("Prevented changing the account selection")
        return false;
    },*/

    $("#bucketEditAccountSelect").change(function(){
        onAccountSelectChanged();
    })

    refreshBucketTableAccountSelect();

    apiRequest(createRequest("get", "account", null, ["ID", "Name"])).then(function(result){
        populateBucketNameMap(result)
        apiRequest(createRequest("get", "bucket", null, ["ID", "Name"])).then(function(result2){
            populateBucketNameMap(result2);
            $('#accountTree').treeview({
                expandIcon: "fas fa-plus",
                collapseIcon: "fas fa-minus",
                //nodeIcon
                //emptyIcon
                //selectedIcon

                showTags: true,
                dataUrl: {
                    method: "POST",
                    url: '/database/apiRequest',
                    contentType: "application/json; charset=utf-8",
                    dataType: "json",
                    data: JSON.stringify(createRequest("get", "account", null, ["ID", "Name", "Balance", "Children"])),
                    dataFilter: function(data, type){
                        var json = JSON.parse(data);
                        if (apiRequestSuccessful(json)){
                            return JSON.stringify(apiResponseToTreeView(json));
                        }
                        return undefined;
                    }
                },
                lazyLoad: function(node, resultFunc){
                    var data = []
                    //alert(JSON.stringify(node))
                    if(node.dataAttr.childrenIDs){
                        //alert(node.dataAttr.childrenIDs)
                        node.dataAttr.childrenIDs.forEach(function(item, index){
                            data.push({ID: item})
                        });
                    } else {
                        alert("Requested nodes children, but this node has no children " + node.id);
                    }
                    apiRequest(createRequest("get", "bucket", data, ["ID", "Name", "Balance", "Children"]), function(data){
                        resultFunc(apiResponseToTreeView(data))

                        //TODO: This is a very quick fix for the badges not appearing right
                        $(".node-accountTree .badge").attr("class", "badge badge-pill badge-secondary testClass float-right")
                    })
                }
            });

            var initComplete = false;
            $('#accountTree').on('initialized', function(){
               if(!initComplete){
                   onTreeReady();
                   initComplete = true;
               }

               $('#accountTree').on("nodeSelected", function(e, node) {
                   onTreeSelection(e, node);
               });
            })
        });
    });
}

function onTreeReady() {
	lastSelection = getSelectedAccount(); // This will select the first list item and update the lastSelection for use later
	refreshBalanceDisplay(); // Initial update since the usual event handler isn't registered yet
	initTable("transactionTable", "transaction");
	initTable("bucketTable", "bucket");
	initTable("accountTable", "account");
}

function onTreeSelection(e, node) {
    if (lastSelection != getSelectedAccount()){
        if(!getTableData("transactionTable").isLocked()){
            refreshBalanceDisplay();
            $("#transactionTable").jsGrid("render")
            lastSelection = getSelectedAccount();
        } else {
            console.log("The transaction table is locked...")
        }
    } else {
        console.log("Skipping because lastSel: " + lastSelection + " matched")
    }
}

function onTableReady(tableName, table){
	tables[tableName].table = table;
	console.log("Initialized Table: " + tableName);
}

function onAccountSelectChanged() {
    $("#bucketTable").jsGrid("render")
}

function onFormSubmit(self, tableName){
	var form = $("#" + tableName + "EditForm");
	var data = $("#" + tableName + "EditForm").serializeArray()
	var row = form.data('row');
	data.push({name:"ID", value: form.data('rowID')})
	//TODO: Create and implement a generic data validation system
	
	// Call the submit callback for the affected table
	console.log("Form Data: " + tableName + ": " + JSON.stringify(data))
	var result = getTableData(tableName).formCallback(row, data);
	if(result == true){
		hideModal(tableName + "EditFormModal");
	}
	// We return false to prevent the web page from being reloaded
	return false;
}