// ############################## Utility Functions ##############################

function getOrDefault(object, property, def){
	return (object[property] ? object[property] : def);
}

function formGetOrDefault(object, property, def){
	//alert("done0")
	var result = def;
	object.forEach(function(item, index){
		if(item.name == property && item.value){
			result = item.value;
		}
	});
	//alert("done0.1")
	return result;
}

function clearTable(tableName){
	console.log("Clearing Table " + tableName + " (Not; Reason; Unimplemented)")
}

function addTableRows(tableName, rows, accessKey, appendRows){
	var append = (appendRows != undefined);
	if(_isTableSafe_(tableName, accessKey)){
		console.log("Adding: [rows] to " + tableName + ", Append: " + append)
		getTableData(tableName).table.loadRows(rows, append);
	}
}

function deleteTableRows(tableName, rows, accessKey){
	// TODO: rows is actually a single row object but should be an array of rows
	rows.delete();
}

function updateTableRows(tableName, rows, accessKey){
	console.log("Updating: [Rows] in " + tableName)
	rows.forEach(function(item, index){
		item.row.val(item.data)
	});
}

function _isTableSafe_(tableName, accessKey){
	if(!getTableData(tableName).isLocked(accessKey)){
		return true;
	} else {
		console.log("Error: " + tableName + " is locked and cannot be modifed")
	}
	return false;
}

function formToSQLRow(data){
	var obj = {};
	data.forEach(function(item, index){
		obj[item.name] = item.value;
	});
	return obj;
}

function getTableData(tableName){
	var table = tables[tableName];
	if(!table){
		console.log("Table " + tableName + " was undefined")
	}
	return table;
}

function getEnumValue(value, tableName, columnName){
	if (value < 0){
		return "N/A";
	}
	console.log("Loading enum value: " + tableName + "." + columnName + ".[" + value + "]")
	//return enums[tableName][columnName][value];
	return value;
}
// ############################## API Logic ##############################
tables = {}
enums = {}

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
		},
		error: function() {
			alert("Request Error!!");
		}
	});
}

function createRequest(action, type, data){
	//TODO: Verify the input data
	var request = {
		action: action,
		type: type
	}
	
	if(data != undefined){
	   request.data = data;
	}
	
	request.debugTrace = new Error().stack;
	
	return request
}

function apiRequestSuccessful(response){
	if(response.successful == true){
		return true;
	}
	alert("Error: " + response.message);
	return false;
}


function apiResponseToJSTree(response){
	var results = []
	var data = response.data;
	if (data != undefined) {
		//alert(data);
		results = responseToJSTreeNode(data);
		//alert(JSON.stringify(results));
	}
	//alert(JSON.stringify(results));
	return results;
}

function responseToJSTreeNode(data){
	var results = []
	data.forEach(function(item, index) {
		var children = [];
		item.Children.forEach(function(it, ind){
			children.push({"id": it})
		});
		results.push({"id": item.ID, "text": item.Name, "children": (item.Children.length > 0 ? true : false), "childrenIDs": item.Children, "data": {"balance": item.Balance}})
	});
	return results
}


function apiTableSchemaToColumnsOld(data, tableName){
	var columns = []

	data.forEach(function(item, index){
		var props = item.properties;
		if(props){
			var obj = {"data": item.name, "title": props.title, "visible": props.visible};
			
			if (props.type == "enum" || props.type == "mapping"){
				obj.type = "number";
				obj.formatter = function(value, options, rowData){
					if (value < 0){
						return "N/A";
					}
					console.log("Loading enum value: " + tableName + "." + item.name + ".[" + value + "]")
					return enums[tableName][item.name][value];
				};
			} else {
				obj.type = props.type;
			}
			
			//TODO: This is a quick fix for a larger issue
			if(tableName == "accountTable" && item.name == "Parent"){
				//Do nothing
			} else {
				columns.push(obj);
			}
		}
	});
	columns.push({"title": "Actions", "data":null, "defaultContent":getTableRowActionButtons(tableName, columns), "visible": false})
	return columns;
}

function apiTableSchemaToColumns(data, tableName){
	var columns = []

	data.forEach(function(item, index){
		var props = item.properties;
		if(props){
			var obj = {"name": item.name, "title": props.title, "visible": props.visible};
			
			if (props.type == "enum" || props.type == "mapping"){
				obj.type = "number";
				obj.formatter = function(value, options, rowData){
					return getEnumValue(value, tableName, item.name);
				};
			} else {
				obj.type = props.type;
			}
			
			columns.push(obj);
		}
	});
	return columns;
}

/*function getTableRowActionButtons(tableName, columns){
    var del = $('<button>', {class: '', text: "Delete", onclick: "_onRowDelete_(this, \'" + tableName + "\')"});
    var edit = $('<button>', {class: '', text: "Edit", onclick: "_onRowEdit_(this, \'" + tableName + "\')"});
    return edit.prop('outerHTML') + del.prop('outerHTML');
}*/
 
/*function _onRowDelete_(self, tableName){
    var table = getTableData(tableName).table;
    var data = getRowData(self, tableName);
    if(confirm("Delete Row?\n" + JSON.stringify(data))){
        getTableData(tableName).deleteCallback(getRow(self, tableName));
    }
}
 
function _onRowEdit_(self, tableName){
    var data = getRowData(self, tableName);
    showFormModal(tableName, data);
}*/

function apiTableSchemaToSettings(data, tableName){
	var settings = {
		"onUpdate": function(updatedCell, updatedRow, oldValue){
			onTableCellUpdate(tableName, updatedCell, updatedRow, oldValue);
		},
		"inputCss":'table-input-box',
		"confirmationButton": { 
			"confirmCss": 'table-confirm-class',
			"cancelCss": 'table-cancel-class'
		},
		"allowNulls": {
			"columns": [],
			"errorClass": 'table-input-error'
		},
		"inputTypes": []
	}

	data.forEach(function(item, index){
		var props = item.properties;
		
		if (!item.PreventNull){
			settings.allowNulls.columns.push(index)
		}
		
		//alert(item.name + " - " + tableName + "[" + index + "].type" + " = " + props.type);
		if (props.type == "enum" || props.type == "mapping"){
			settings.inputTypes.push({"column": index, "type": "list", "options": []})
			// Now we start the api request to actually populate the list
			// This occurs async
			//{ "value": "1", "display": "Beaty" },
		} else if (props.type == "date"){
			settings.inputTypes.push({"column": index, "type": "date", "options": null})
		}
		//Else: Go with the default
	});
	return settings;
}

function apiTableSchemaToEditForm(data, tableName){
	var columns = []

	data.forEach(function(item, index){
		var props = item.properties;
		var titleStr = (props ? props.title : item.name); 
		
		var div = $("<div></div>");
		div.append($('<span>' + titleStr + ':<br></span>'));
		
		var input = null;
		var typeStr = 'text';
		if(props.type == "date"){
			typeStr = "date"
		} else if (props.type == "number"){
			typeStr = "number"
		} else if (props.type == "enum" || props.type == "mapping"){
			typeStr = "number"
			//TODO: Do nothing for now but eventualy generate a select
		}
		
		// Prevent null is listed last to make the "required" given by spent-server.py have priority
		var requiredStr = ((props.required && props.required == true) || item.PreventNull == true)
		
		var input = $('<input type="' + typeStr + '"step="0.01" value=' + "" + requiredStr + ">");
		input.attr("name", item.name)
		div.append(input)

		columns.push(div);
	});
	
	var form = $("<form id=\"" + tableName + "EditForm\" onsubmit='return onFormSubmit(this, \"" + tableName + "\")' method='GET'></form>")
	columns.forEach(function(item, index){
		form.append(item);
	});
	
	form.append("<input type='submit' value='Submit'>")
	return form;
}

// ############################## GUI Control ##############################

function initTable(tableName, apiDataType){
	$.get({
		url: "/database/schema/columns?tableName=" + tableName,
		success: function(data) {
			console.log("Initializing Table: " + tableName);
			tables[tableName] = {
				apiDataType: apiDataType,
				columns: apiTableSchemaToColumns(data, tableName),
				settings: apiTableSchemaToSettings(data, tableName),
				table: {
					loadRows: function(a, b){
						console.log("Warning: loadRows called before table was ready");
					}
				},
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
					if (lockID && lockID == this.lockID){
						console.log("Table " + tableName + " can be accessed by " + lockID);
						result = false;
					}
						
					console.log("Table " + tableName + " is " + (result ? "locked with key " + this.lockID : "not locked"))
					//return false;
					return result;
				},
				formCallback: function(tableRow, data){
					if(tableRow){
						onUpdateRow(tableName, tableRow, data);
					} else {
						onCreateRow(tableName, data);
					}
					//TODO: make this actually reflect whether the callback completed sucessfully
					return true;
				},
				deleteCallback: function(tableRow){
					//alert("Delete Callback");
					onDeleteRow(tableName, tableRow);
					
					return true;
				}
			};
			
			$("#" + tableName).on('ready.ft.table', function(e, table){
				onTableReady(tableName, table);
			});
			
			//var unlockKey = tables[tableName].lockTable();
			$("#" + tableName).footable({
				columns: getTableData(tableName).columns,
				editing: {
					enabled: true,
					addRow: function(){
						showFormModal(tableName, null)
					},
					editRow: function(row){
						showFormModal(tableName, row);
					},
					deleteRow: function(row){
						var table = getTableData(tableName).table;
						if(confirm("Delete Row?")){
							getTableData(tableName).deleteCallback(row);
						}
					}
				}
			});
			
			// Now create the edit toolbar
			var toolbar = $("#" + tableName + "EditToolbar");
			if(toolbar){
				//initTableEditBar(toolbar, tableName);
				//disableTableEdit(tableName);
			}
			
			// Followed by the row edit form
			var editForm = $("#" + tableName + "EditFormDiv");
			if(editForm){
				initTableEditForm(editForm, apiTableSchemaToEditForm(data, tableName), tableName);
			}
			//tables[tableName].unlockTable(unlockKey)
		}
	});
}

/*function initTableEditBar(toolbar, tableName){
    toolbar.append($('<button>', {id: tableName + "SelectToggleButton", class: '', text: "Edit", onclick: "enableTableEdit(\'" + tableName + "\')"}))
    toolbar.append($('<button>', {id: tableName + "ConfirmEditButton", class: '', text: "Done", onclick: "confirmTableEdit(\'" + tableName + "\')"}))
     
    toolbar.append($('<button>', {id: tableName + "AddRowButton", class: '', text: "Add Row"}).click(function(e){
        showFormModal(tableName, {})
    }))
}*/

function initTableEditForm(editFormDiv, editForm, tableName){
	editFormDiv.append(editForm)
}

function drawTable(tableName){
	getTableData(tableName).table.draw()
}

function refreshTable(tableName){
	//alert("Table: " + tables[tableName].table);
	if(getTableData(tableName).table){
		console.log("Refreshing Table: " + tableName);
		if(!getTableData(tableName).isLocked()){
			clearTable(tableName);
			//TODO: This chained "if" should be replaced with something less... static
			if(tableName == "transactionTable" || tableName == "bucketTable"){
				var accountID = (tableName == "transactionTable" ? getSelectedAccount() : getSelectedBucketTableAccount())
				apiRequest(createRequest("get", "bucket", [{"ID": accountID, "AllChildren": null}]), function(response) {
					var unlockKey = getTableData(tableName).lockTable();	

					var buckets = [];
					response.data.forEach(function(item3, index3){
						buckets.push({"ID": item3.ID, "Transactions": null, "Name": null, "Parent": null});
					});

					apiRequest(createRequest("get", "bucket", buckets), function(response) {
						if(tableName == "bucketTable"){
							//alert("refreshung bucket table");
							addTableRows(tableName, response.data, unlockKey);
							getTableData(tableName).unlockTable(unlockKey);	
						} else if(tableName == "transactionTable"){
							var data = []
							response.data.forEach(function(item, index){
								item.Transactions.forEach(function(item2, index2){
									data.push({"ID": item2, "Status": null, "TransDate": null, "PostDate": null, "Amount": null, "SourceBucket": null, "DestBucket": null, "Memo": null, "Payee": null});
								});
							});
							apiRequest(createRequest("get", "transaction", data), function(response) {
								//alert("Filling Transactions");
								addTableRows(tableName, response.data, unlockKey);
								getTableData(tableName).unlockTable(unlockKey);
							});	
						}
					});		
				});
			} else if (tableName == "accountTable"){
				apiRequest(createRequest("get", "account", null), function(response) {
					var unlockKey = getTableData(tableName).lockTable();
					var accounts = [];
					response.data.forEach(function(item3, index3){
						accounts.push({"ID": item3.ID, "Name": item3.Name});
					});
					addTableRows(tableName, accounts, unlockKey);
					getTableData(tableName).unlockTable(unlockKey);
				});
			} else {
				alert("Unknown table: " + tableName);	
			}
		} else {
			console.log("Error: " + tableName + " is locked and cannot be refreshed")
		}
	} else {
		console.log("refreshTable: Table " + tableName + " is not ready yet!");
	}
}

function refreshSidebarAccountSelect(){
	$('#accountTree').jstree('refresh');
}

function refreshBucketTableAccountSelect() {
	// Bucket Editor
	$.get({
		url: "/database/getAccounts?format=html-select",
		success: function(data) {
			var select = $("#bucketEditAccountSelect");
			select.options.length = 0; // Clear the options
			//TODO Finish me!!!
		}
	});
}

function refreshBalanceDisplay() {
	if (getSelectedAccount() != undefined) {
		apiRequest(createRequest("get", "bucket", [{"ID": getSelectedAccount(), "Balance": null, "PostedBalance": null}]), function(response) {
			$("#balanceDisplay").text("Available: \$" + response.data[0]["Balance"] + ", Posted: \$" + response.data[0]["PostedBalance"]);
		});
	} else {
		$("#balanceDisplay").text("Error fetching balance");
	}
}

function getSelectedAccount() {
	var selected = $('#accountTree').jstree('get_selected', false);
	if (selected == "") {
		$('#accountTree').jstree('select_node', 'ul > li:first');
		selected = $('#accountTree').jstree('get_selected', false);
	}
	return selected[0]
}

function getSelectedBucketTableAccount(){
	
}

/*function toggleTableEditToolbar(tableName, state){
	//alert("Table Toggle " + state);
	$("#" + tableName + "SelectToggleButton").toggle(!state)

	$("#" + tableName + "CancelEditButton").toggle(state)
	$("#" + tableName + "ConfirmEditButton").toggle(state)

	$("#" + tableName + "AddRowButton").toggle(state)
	$("#" + tableName + "DeleteSelectedButton").toggle(state)
}

function enableTableEdit(tableName){
	toggleTableEditToolbar(tableName, true);
	var col = getTableData(tableName).columns.length - 1;
	getTableData(tableName).table.column(col).visible(true)
}

function disableTableEdit(tableName){
	toggleTableEditToolbar(tableName, false);
	var col = getTableData(tableName).columns.length - 1;
	getTableData(tableName).table.column(col).visible(false)
}

function cancelTableEdit(tableName){
	//Do cancel
	
	disableTableEdit(tableName);
}

function confirmTableEdit(tableName){
	// Do confirm
	
	disableTableEdit(tableName);
}*/

function showFormModal(tableName, row){
	var data = (row ? row.val() : {});
	var form = $(updateFormContent(tableName + "EditForm", data))
	form.data('row', row);
	showModal(tableName + "EditFormModal");
}

// ############################## Event Handlers ##############################

function onDocumentReady() {
	//This is first so that the event will surely be registered before it is fired
	enums.transactionTable = []
	enums.transactionTable.Status = ["Uniniated", "Submitted", "Post Pending", "Complete"];
	//enums.transactionTable.SourceBucket = ["A", "B", "C", "D"];
	//enums.transactionTable.DestBucket = ["A", "B", "C", "D"];
	
	$('#accountTree').on("ready.jstree", function(e, data) {
		onJSTreeReady();
	});
	$('#accountTree').jstree({
		core: {
			animation: false,
			data: {
				method: "POST",
				url: function(node) {
					return '/database/apiRequest';
				},
				contentType: "application/json; charset=utf-8",
				dataType: "json",
				data: function(node) {
					var data = []
					
					if(node.id == "#"){
						data = null
					} else {
						//alert(JSON.stringify(node));
						if(node.original.childrenIDs){
							node.original.childrenIDs.forEach(function(item, index){
								data.push({ID: item, Children: null, Balance: null, Name: null})
							});
						} else {
							alert("Requested nodes children, but this node has no children " + node.id);
						}
					}
					
					return JSON.stringify({	 
						action: "get",
						type: (node.id == "#" ? "account" : "bucket"),
						data: data
					})
				},
				dataFilter: function(data, type){
					var json = JSON.parse(data);
					if (apiRequestSuccessful(json)){
						return JSON.stringify(apiResponseToJSTree(json));
					}
					return undefined;
				}
			}
		},
		conditionalselect : function (node, event) {
			// TODO: A slightly more robust condition is better as the trans table is not the only table affected by this option
			if(!getTableData("transactionTable").isLocked()){
				console.log("Prevented changing the account selection")
				return true;
			}
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
			//"wholerow",
			//"changed",
			"conditionalselect",
			"grid"
		],
		grid: {
			columns: [{
				tree: true,
				header: "Accounts"
			}, {
				tree: false,
				header: "Balance",
				value: "balance"
			}],
		},
	});
}

function onJSTreeReady() {
	getSelectedAccount(); // This will select the first list item
	refreshBalanceDisplay(); // Initial update since the usual event handler isn't registered yet
	initTable("transactionTable", "transaction");
	initTable("bucketTable", "bucket");
	initTable("accountTable", "account");
	
	$('#accountTree').on("changed.jstree", function(e, data) {
		onJSTreeChanged(e, data);
	});
	$('#accountTree').on("refresh.jstree", function(e, data) {
		onJSTreeRefreshed(e, data);
	});
}

function onJSTreeChanged(e, data) {
	if (data.action == "select_node") {
		refreshBalanceDisplay();
		refreshTable("transactionTable");
	} else if (data.action == "deselect_all") {} else {
		alert("onJSTreeChanged: Unknown action: " + data.action);
	}
}

function onJSTreeRefreshed(e, data) {

}

function onTableReady(tableName, table){
	// Load the table
	tables[tableName].table = table;
	console.log("Initialized Table: " + tableName);
	refreshTable(tableName);
}

function onAccountSelectChanged() {

}

function onFormSubmit(self, tableName){
	var form = $("#" + tableName + "EditForm");
	var data = $("#" + tableName + "EditForm :input[value!='']").serializeArray()
	var row = form.data('row');
	//TODO: Create and implement a generic data validation system
	
	// Call the submit callback for the affected table
	console.log(tableName + ": " + JSON.stringify(data))
	var result = getTableData(tableName).formCallback(row, data);
	if(result == true){
		hideModal(tableName + "EditFormModal");
	}
	// We return false to prevent the web page from being reloaded
	return false;
}

function onCreateRow(tableName, data){
	//alert("a")
	apiRequest(createRequest("create", getTableData(tableName).apiDataType, [formToSQLRow(data)]), function(result){
		var unlockKey = getTableData(tableName).lockTable();
		addTableRows(tableName, result.data, unlockKey, true);
		//drawTable(tableName);
		getTableData(tableName).unlockTable(unlockKey);
		refreshBalanceDisplay();
		refreshSidebarAccountSelect();
	});
}

function onDeleteRow(tableName, tableRow){
	var data = {};
	var rowData = tableRow.val()
	getTableData(tableName).columns.forEach(function(item, index){
		var key = item.name;
		data[key] = rowData[key];
	});
	apiRequest(createRequest("delete", getTableData(tableName).apiDataType, [data]), function(result){
		var unlockKey = getTableData(tableName).lockTable();
		//refreshTable(tableName); //TODO: Replace this with single row update
		deleteTableRows(tableName, tableRow, unlockKey);
		//drawTable(tableName);
		getTableData(tableName).unlockTable(unlockKey);
		refreshBalanceDisplay();
		refreshSidebarAccountSelect();
	});
}

function onUpdateRow(tableName, tableRow, data){
	//alert("b")
	apiRequest(createRequest("update", getTableData(tableName).apiDataType, [formToSQLRow(data)]), function(result){
		var unlockKey = getTableData(tableName).lockTable();
		var rows = [{row: tableRow, data: result.data[0]}] // Todo: Add support for updating multiple rows at once
		updateTableRows(tableName, rows, unlockKey);
		//refreshTable(tableName); //TODO: Replace this with single row update
		//drawTable(tableName);
		getTableData(tableName).unlockTable(unlockKey);
		refreshBalanceDisplay();
		refreshSidebarAccountSelect();
	});
}