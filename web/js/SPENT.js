var tables = {}
var tableSchema = {}
var enums = {}
var lastSelection = null;

// Create our number formatter.
var formatter = null;

// ############################## Utility Functions ##############################

function getOrDefault(object, property, def){
	return (object[property] ? object[property] : def);
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
	if(_isTableSafe_(tableName, accessKey)){
		rows.delete();
	}
}

function updateTableRows(tableName, rows, accessKey){
	if(_isTableSafe_(tableName, accessKey)){
		console.log("Updating: [Rows] in " + tableName)
		rows.forEach(function(item, index){
			item.row.val(item.data)
		});
	}
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

function _getNodeForID_(id){
	return $('#accountTree').jstree().get_node(id)
}

function getBucketNameForID(id){
	if(id < 0){
	   return "N/A";
	}
	
	var node = _getNodeForID_(id);
	if(node != false){
		return node.text;	
	}
	
	return "Invalid ID: " + id;
}

function getBucketParentForID(id){
	if(id < 0){
	   return "N/A";
	}
	
	var node = _getNodeForID_(id);
	if(node != false){
		var par = node.parent;
		if(par == "#"){
			return -1
		}
		return par;
	}
	
	return "Invalid ID: " + id;
}

function getNodeType(node){
	return (node.parent == "#" ? "account" : "bucket")
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
				return data;
			}
		},
		error: function(data) {
			alert("Request Error!!\n" + JSON.stringify(data));
		}
	});
}

function createRequest(action, type, data, columns){
	//TODO: Verify the input data
	var request = {
		action: action,
		type: type
	}
	
	if(data != undefined){
	   request.data = data;
		if(data.length < 1){
			request.data = null;
		}
	}
	
	if(columns != undefined){
	   request.columns = columns;
	}
	
	//request.debugTrace = new Error().stack;
	
	return request
}

function apiRequestSuccessful(response){
	if(response.successful == true){
		return true;
	}
	alert("API Error: " + response.message);
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

function apiTableSchemaToColumns(tableName){
	//TODO: Consider removing the need for this function by using the tableSchema object as the columns
	var columns = []
	tableSchema[tableName].columns.forEach(function(item, index){
		var obj = {"name": (item.name ? item.name : item.title ), "title": item.title};

		if(item.visible != undefined){
		   obj.visible = item.visible
		}
		   
		if(item.breakpoints){
			obj.breakpoints = item.breakpoints;
		}
		
		if(item.formatString){
			obj.formatString = item.formatString;	
		}

		if(item.sortValue){
			obj.sortValue = item.sortValue;
		}
		
		if(item.formatter){
			obj.formatter = item.formatter;
		}
		
		switch(item.type){
			case "enum":
				obj.type = "string"
				obj.formatter = function(value, options, rowData){
					return enums[tableName][obj.name][value];
				};
				break;
			case "formatter":
				obj.type = "string"
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
					
					//TODO: This is a quick fix; 
					//The ID currently must be on the form in
					//order for it to get sent to the server. 
					//If it's not then the server can't determine
					//where the updated data shoud go
					if (item.name == "ID"){
						input.prop("readonly", true);
					}
					
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
						
						//TODO: This is a quick fix
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
			if(tableRow){
				onUpdateRow(tableName, tableRow, data);
			} else {
				onCreateRow(tableName, data);
			}

			refreshBalanceDisplay();
			refreshSidebarAccountSelect();
			//TODO: make this actually reflect whether the callback completed sucessfully
			return true;
		},
		deleteCallback: function(tableRow){
			//alert("Delete Callback");
			onDeleteRow(tableName, tableRow);
			refreshBalanceDisplay();
			refreshSidebarAccountSelect();
			return true;
		}
	};

	$("#" + tableName).on('ready.ft.table', function(e, table){
		onTableReady(tableName, table);
	});


	$("#" + tableName).footable({
		columns: getTableData(tableName).columns,
		editing: {
			enabled: true,
			addRow: function(){
				showFormModal(tableName, null, "New Row")
			},
			editRow: function(row){
				showFormModal(tableName, row, "Edit Row");
			},
			deleteRow: function(row){
			    //TODO: Replace this with a modal
				var table = getTableData(tableName).table;
				var data = row.val();
				//TODO: The amount field is the raw value, we really want the pretty amount string
				//TODO: And this only works right for the transaction table's form
				var rowText = data.Amount + " - " + data.Memo

				if(confirm("Delete Row?\n" + rowText)){
					getTableData(tableName).deleteCallback(row);
				}
			}
		}
	});

	// Create the row edit form
	var editForm = $("#" + tableName + "EditFormDiv");
	if(editForm){
		initTableEditForm(editForm, apiTableSchemaToEditForm(tableName), tableName);
	}
}

function initTableEditForm(editFormDiv, editForm, tableName){
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
    var rules_basic = {
      condition: 'AND',
      rules: [{
        id: 'price',
        operator: 'less',
        value: 10.25
      }, {
        condition: 'OR',
        rules: [{
          id: 'category',
          operator: 'equal',
          value: 2
        }, {
          id: 'category',
          operator: 'equal',
          value: 1
        }]
      }]
    };

    $('#transactionTableFilter').queryBuilder({

  filters: [{
    id: 'name',
    label: 'Name',
    type: 'string'
  }, {
    id: 'category',
    label: 'Category',
    type: 'integer',
    input: 'select',
    values: {
      1: 'Books',
      2: 'Movies',
      3: 'Music',
      4: 'Tools',
      5: 'Goodies',
      6: 'Clothes'
    },
    operators: ['equal', 'not_equal', 'in', 'not_in', 'is_null', 'is_not_null']
  }, {
    id: 'in_stock',
    label: 'In stock',
    type: 'integer',
    input: 'radio',
    values: {
      1: 'Yes',
      0: 'No'
    },
    operators: ['equal']
  }, {
    id: 'price',
    label: 'Price',
    type: 'double',
    validation: {
      min: 0,
      step: 0.01
    }
  }, {
    id: 'id',
    label: 'Identifier',
    type: 'string',
    placeholder: '____-____-____',
    operators: ['equal', 'not_equal'],
    validation: {
      format: /^.{4}-.{4}-.{4}$/
    }
  }],

  rules: rules_basic
    });
}

function refreshTable(tableName){
	//alert("Table: " + tables[tableName].table);
	if(getTableData(tableName).table){
		console.log("Refreshing Table: " + tableName);
		if(!getTableData(tableName).isLocked(null)){
			
			var unlockKey = getTableData(tableName).lockTable();
			
			switch(tableName){
				case "accountTable":
					apiRequest(createRequest("get", "account", null), function(response) {
						var accounts = [];
						response.data.forEach(function(item3, index3){
							accounts.push({"ID": item3.ID, "Name": item3.Name});
						});
						
						addTableRows(tableName, accounts, unlockKey);
						getTableData(tableName).unlockTable(unlockKey);
					});
					break;
				case "bucketTable":
					apiRequest(createRequest("get", "bucket", [{"ID": getSelectedBucketTableAccount()}]), function(response) {
						var buckets = [];
						response.data.forEach(function(item3, index3){
							buckets.push({"ID": item3.ID});
						});

						apiRequest(createRequest("get", "bucket", buckets, ["Transactions", "Name", "Parent"]), function(response) {
							addTableRows(tableName, response.data, unlockKey);
							getTableData(tableName).unlockTable(unlockKey);	
						});
					});
					break;
				case "transactionTable":
					var node = _getNodeForID_(getSelectedAccount())
					var parent = getBucketParentForID(node.id);
					
					requestColumns = ["Transactions"]
					if(parent == -1){
						requestColumns = ["AllTransactions"]
					}

					apiRequest(createRequest("get", getNodeType(node), [{"ID": parseInt(node.id)}], requestColumns), function(response) {
						var data = []
						var ids = new Set()
						response.data.forEach(function(item, index){
							item[requestColumns[0]].forEach(function(item2, index2){
								ids.add(item2)
							});
						});

						ids.forEach(function(item, index){
							data.push({"ID": item})
						})

						if (data.length > 0) {
							apiRequest(createRequest("get", "transaction", data, ["Status", "TransDate", "PostDate", "Amount", "SourceBucket", "DestBucket", "Memo", "Payee", "Type"]), function(response) {
								addTableRows(tableName, response.data, unlockKey);
								getTableData(tableName).unlockTable(unlockKey);
							});	
						} else {
							addTableRows(tableName, [], unlockKey);
							getTableData(tableName).unlockTable(unlockKey);
						}
					});		
					break;
				default:
					alert("Unknown table: " + tableName);
			}

			//console.log("Table: " + tableName + " Done Refreshing")
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
		var node = _getNodeForID_(getSelectedAccount());
		apiRequest(createRequest("get", getNodeType(node), [{"ID": node.id}], ["Balance", "PostedBalance"]), function(response) {
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
	/*
	$("#elementId :selected").text(); // The text content of the selected option
$("#elementId :selected").val(); // The value of the selected option
	*/
}

function showFormModal(tableName, row, title){
	var data = (row ? row.val() : {});
	var form = $(updateFormContent(tableName + "EditForm", data, title))
	var inputs = form.find("select").toArray();
	inputs.forEach(function(item, index){
		var it = $(item)
		var needsUpdate = it.data("isDynamic");
		if(needsUpdate != undefined){
			if(needsUpdate()){
				rowVal = -1;
				if(row){
					rowVal = row.val()[it[0].name];
				}
				updateDynamicInput(it, rowVal);
			}
		}
	});
	form.data('row', row);
	form.data('rowID', data.ID);
	showModal(tableName + "EditFormModal");
}

function updateDynamicInput(it, value){
	it.prop("disabled", true);

	// After the function completes it shoud re-enable the input
	it.data("optionFunc")().then(function(result){
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

// ############################## Column Formatters ##############################

function getBucketOptions(){
	//TODO: Rewrite this to account for the selected account and whether the type is set as "transfer"
	var array = [];
	return apiRequest(createRequest("get", "account")).then(function(result){
		result.data.forEach(function(item, index){
			array.push({"ID": item.ID, "Name": item.Name})
		});
		return apiRequest(createRequest("get", "bucket"));
	}).then(function(result2){
		//alert("Hello World")

		result2.data.forEach(function(item, index){
			array.push({"ID": item.ID, "Name": "    " + item.Name})
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

function getTransferDirection(rowData, bucketID){
	// True = Money Coming in; I.E. a positive value
	// False = Money Going out; I.E. a negative value
	switch(rowData.Type){
		case "0":
			return (rowData.DestBucket == bucketID);
			break;
		case "1":
			return true;
			break;
		case "2":
			return false;
			break;
	}
	return null;
}

function transactionTypeFormatter(value, options, rowData){
	if(rowData.typeSort){
	   return rowData.typeSort;
	}
	rowData.typeSort = rowData.Type
	var fromToStr = "";
	if (rowData.typeSort == "0"){//Transfer
		fromToStr = (getTransferDirection(rowData, getSelectedAccount()) ? " from " : " to ");
	}
	return enums["transactionTable"]["Type"][rowData.typeSort] + fromToStr;
}

function transactionAmountFormatter(value, options, rowData){
	if(rowData.amountSort){
	   return rowData.amountSort;
	}

	var isDeposit = getTransferDirection(rowData, getSelectedAccount());
	if (isDeposit){
		// If deposit
		rowData.amountSort = formatter.format(value);
		return rowData.amountSort;
	}
	rowData.amountSort = formatter.format(value * -1);
	return rowData.amountSort;
}

function bucketFormatter(value, options, rowData){
	if(rowData.bucketSort){
	   return rowData.bucketSort;
	}
	var id = -2; //This value will cause the name func to return "Invalid ID"

	var transType = rowData.Type;
	var isDeposit = (rowData, getSelectedAccount());
	if(transType != "0"){
		id = (transType == "1" ? rowData.DestBucket : rowData.SourceBucket);
	} else {
		id = (rowData.SourceBucket == getSelectedAccount() ? rowData.DestBucket : rowData.SourceBucket);
	}

	var par = getBucketParentForID(id);
	//if(par != -1){
	rowData.bucketSort = getBucketNameForID(id);
	/*} else {
		rowData.bucketSort = "Unassigned";
	}*/
	return rowData.bucketSort;
}

function transactionDateFormatter(value, options, rowData){
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
	
	tableSchema = {
		accountTable: {
			columns: [
				{name: "ID", visible: false, formVisible: false},
				{name: "Name", title: "Name", type: "string", required: true, formType: "text"}
			]
		},
		bucketTable: {
			columns: [
				{name: "ID", visible: false, formVisible: false},
				{name: "Name", title: "Name", type: "string", required: true, formType: "text"},
				{name: "Parent", title: "Parent", type: "formatter", formatter: bucketFormatter, required: true, formType: "select", options: getBucketOptions, formDynamicSelect: function(){ return true; }}
			]
		},
		transactionTable: {
			columns: [
				{name: "ID", visible: false, formVisible: false},
				{name: "Status", title: "Status", type: "enum", breakpoints:"xs sm md", formType: "select", options: getStatusOptions, required: true},
				{name: "TransDate", title: "Date", type: "date", breakpoints:"xs", formatString:"YYYY-MM-DD", required: true, formType: "date"},
				{name: "PostDate", title: "Posted", type: "date", breakpoints:"xs sm md", formatString:"YYYY-MM-DD", formType: "date", formatter: transactionDateFormatter},
				{name: "Amount", title: "Amount", type: "formatter", breakpoints:"", required: true, formType: "number", formatterType: "number", formatter: transactionAmountFormatter},
				{name: "Type", title: "Type", type: "formatter", breakpoints:"xs sm md", required: true, formType: "select", options: getTypeOptions, formatter: transactionTypeFormatter},
				{title: "Bucket", type: "formatter", breakpoints:"xs sm md", formVisible: false, formatter: bucketFormatter},
				{title: "Source", name: "SourceBucket", required: true, formType: "select", options: getBucketOptions, visible: false, formDynamicSelect: function(){ return true; }},
				{title: "Destination", name: "DestBucket", required: true, formType: "select", options: getBucketOptions, visible: false, formDynamicSelect: function(){ return true; }},
				{name: "Memo", title: "Memo", type: "string", breakpoints:"", formType: "textbox"},
				{name: "Payee", title: "Payee", type: "string", breakpoints:"xs sm", formType: "text"}
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
	//initFilterModal()

	//This is first so that the event will surely be registered before it is fired
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
			"conditionalselect",
			"grid"
		],
		grid: {
			width: "100%",
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
	$('#accountTree').jstree().load_all();
}

function onJSTreeReady() {
	lastSelection = getSelectedAccount(); // This will select the first list item and update the lastSelection for use later
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
		console.log("JS TREE CHANGE------------------------------------------------")
		if (lastSelection != getSelectedAccount()){
            refreshBalanceDisplay();
            refreshTable("transactionTable");
            lastSelection = getSelectedAccount();
		} else {
		    console.log("Skipping because lastSel: " + lastSelection + " matched")
		}
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
	var data = $("#" + tableName + "EditForm").serializeArray()
	var row = form.data('row');
	data.push({name:"ID", value: form.data('rowID')})
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
	apiRequest(createRequest("create", getTableData(tableName).apiDataType, [formToSQLRow(data)]), function(result){
		var unlockKey = getTableData(tableName).lockTable();
		addTableRows(tableName, result.data, unlockKey, true);
		getTableData(tableName).unlockTable(unlockKey);
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
		deleteTableRows(tableName, tableRow, unlockKey);
		getTableData(tableName).unlockTable(unlockKey);
	});
}

function onUpdateRow(tableName, tableRow, data){
	apiRequest(createRequest("update", getTableData(tableName).apiDataType, [formToSQLRow(data)]), function(result){
		var unlockKey = getTableData(tableName).lockTable();
		var rows = [{row: tableRow, data: result.data[0]}] // Todo: Add support for updating multiple rows at once
		updateTableRows(tableName, rows, unlockKey);
		getTableData(tableName).unlockTable(unlockKey);
	});
}
