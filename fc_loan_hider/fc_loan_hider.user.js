// ==UserScript==
// @name        Funding Circle Loan Hider
// @namespace   http://www.flash.org.uk
// @version     0.1
// @description Enables you to hide loans you don't like so that you don't bid on or buy parts accidentally in future
// @match       https://www.fundingcircle.com/secondary-market
// @require     https://sdk.amazonaws.com/js/aws-sdk-2.0.0-rc13.min.js
// @updateURL   https://github.com/realflash/odds-and-ends/raw/master/fc_loan_hider/fc_loan_hider.user.js
// @copyright   2014+, Ian Gibbs
// @grant       none
// ==/UserScript==
var tableName = 'fcloans';
var accessKey = '';
var secret = '';
var region = 'eu-west-1';

AWS.config.update({accessKeyId: accessKey, secretAccessKey: secret, region: region});
var db = new AWS.DynamoDB({params: {TableName: tableName}});

// Check the configured table exists
db.listTables({}, function (err, data)
{
	var found = false;
	if (err) console.log(err, err.stack); // an error occurred
	// Check the configured table name exists
	for(var i = 0; i < data.TableNames.length; i++)
	{
		if(data.TableNames[i] == tableName) found = true;
	}
	if(!found) window.alert("ERROR: The configured table '" + tableName + "' does not exist in DynamoDB region '" + region + "'");
});

openAdvancedSettings();
var timeout;
listenForChanges();

function openAdvancedSettings()
{
	$('fieldset.advanced-filters').css("display", "block");
	$('a#hide-advanced-filters').css("display", "inline");
	$('a#show-advanced-filters').css("display", "none");
}

function listenForChanges()
{
	$('div.loan-parts-table').on("DOMNodeRemoved", function () {
		clearTimeout(timeout);
		timeout = setTimeout(function() {
			console.log("changed");
			writeVisiblityControls();
		}, 2000);
	});
}

function dontListenForChanges()
{
	$('div.loan-parts-table').off("DOMNodeRemoved");
}

function writeVisiblityControls()
{
	dontListenForChanges();
	$('<th>Visibility</th>').insertBefore("table.loan-parts > thead:nth-child(1) > tr:nth-child(1) > th:nth-child(1)");
	var hideLink = $('<td class="loan-details"><a>Hide</a></td>');
	hideLink.click(function() { toggle($(this)) });
	hideLink.insertBefore("td.loan-details");
	$("tr").data("visible", "true");

	// Load the state of all the loans on the page
	// Collect all the loan IDs
	var loan_ids = [];
	var loan_rows = [];
	$("tr").each(function(index) {
		var children = $(this).children("td");
		if (children.length > 0)
		{
			var id = children.first().next().children("p").first().text().match(/[0-9]+/)[0];
			loan_ids.push({loan_id: {N: id}});
			loan_rows.push({id: id, row: $(this)});
		}
	});
	// Get all those which are stored in the DB
	var req = {};
	req[tableName] = { Keys: loan_ids };
	db.batchGetItem({RequestItems: req}, function (err, data)
		{
			if (err) throw(err.stack); // an error occurred
			else
			{
				var loans = data.Responses[tableName];
				// Convert from array to object
				var indexed_loans = {};
				for(var i = 0; i < loans.length; i++)
				{
						indexed_loans[loans[i].loan_id.N] = true;
				}
				// Hide as appropriate
				for(var i = 0; i < loan_rows.length; i++)
				{
					if(indexed_loans.hasOwnProperty(loan_rows[i].id)) hide(loan_rows[i].row);
				}
			}
		});
		setTimeout(function() {
			console.log("re-enable listen");
			listenForChanges();
		}, 2000);
}
	
// Hides part of a row so it can't be clicked, and logs what was hidden to a DB
function toggle(source)
{
	console.log("toggle");
	dontListenForChanges();
	var row = source.parent();
	var details = row.children("td").first().next();
	var loan_id = details.children("p").first().text().match(/[0-9]+/)[0];
	var loan_tag = details.children("a").first();
	var loan_link = loan_tag.attr("href");
	var loan_description = loan_tag.text();
	
	if(row.data("visible") == "true")
	{
		var now = new Date(Date.now());
		//var update = 'SET link=:' + loan_link + ',description=:' + loan_description + ',visible=:false,modified=:' + now.toISOString()
		var loan = { 
			link: { Value: { S: loan_link },
					Action: 'PUT' },
			description: { Value: { S: loan_description },
							Action: 'PUT' },
			visible: { Value: { S: 'true' },
						Action: 'PUT' },
			modified: { Value: { S: now.toISOString() },
						Action: 'PUT' }
		}
		db.updateItem({Key: { loan_id: {N: loan_id} }, AttributeUpdates: loan}, function (err, data)
			{
				if (err) throw(err.stack); // an error occurred
				else hide(row);
			});
	}
	else
	{
		db.getItem({Key: { loan_id: {N: loan_id} }}, function (err, data)
			{
				if (err) throw(err.stack); // an error occurred
				else show(row, data.Item.description.S);
			});
		db.deleteItem({Key: { loan_id: {N: loan_id} }}, function (err, data)
			{
				if (err) throw(err.stack); // an error occurred
			});
	}
	setTimeout(function() {
		console.log("re-enable listen");
		listenForChanges();
	}, 2000);
}

// Hides the loan description in a certain row
function hide(row)
{
	// Now the details have been stored, we can hide it from view
	row.children("td").first().next().children("a").text("Hidden");
	row.children("td").first().children("a").text("Show");
	row.data("visible", "false");
}

// Reinstates the loan description in a certain row
function show(row, description)
{
	// Now the details have been stored, we can hide it from view
	row.children("td").first().next().children("a").text(description);
	row.children("td").first().children("a").text("Hide");
	row.data("visible", "true");
}
