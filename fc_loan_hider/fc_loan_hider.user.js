// ==UserScript==
// @name        Funding Circle Loan Hider
// @namespace   http://www.flash.org.uk
// @version     0.1
// @description Enables you to hide loans you don't like so that you don't bid on or buy parts accidentally in future
// @match       https://www.fundingcircle.com/secondary-market
// @match		https://www.fundingcircle.com/lend/loan-requests/*
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

var primary = onPrimaryMarket();		// Work out whether we are on the primary market or the secondary market

openAdvancedSettings();					// If there are advanced filters, show them

var timeout;
if(primary)
{	// in the primary market every click that would change the content of the table reloads the page
	writeVisiblityControls();			// so we can write our links straight away
}
else
{	// in the secondary market, the table content reloads without the page reloading
	listenForChanges();					// so we listen to the div containing the table for changes and then write our links
}

// Detect whether the open page is the primary or secondary market
function onPrimaryMarket()
{
	if(document.URL == 'https://www.fundingcircle.com/lend/loan-requests/') return true;
	else return false;
}

function openAdvancedSettings()
{
	if(primary)
	{
		$('div#filter_form').css("display", "block");
		$('a#showfilterbtn > span').text("Hide Filters");
	}
	else
	{
		$('fieldset.advanced-filters').css("display", "block");
		$('a#hide-advanced-filters').css("display", "inline");
		$('a#show-advanced-filters').css("display", "none");
	}
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
	if(primary)	// the tables are built differently, so we need different jquery actions for each
	{
		$("form#watch_form > table:nth-child(1) > thead:nth-child(1) > tr:nth-child(1) > th:nth-child(1)").text("Visibility");
		$("form#watch_form > table:nth-child(1) > tbody > tr > td:nth-child(1)").replaceWith("<td style='cursor: pointer;'><a>Hide</a></td>");
		$("form#watch_form > table:nth-child(1) > tbody > tr > td:nth-child(1)").click(function() { toggle($(this)) });
	}
	else
	{
		dontListenForChanges();
		$('<th>Visibility</th>').insertBefore("table.loan-parts > thead:nth-child(1) > tr:nth-child(1) > th:nth-child(1)");
		var hideLink = $('<td class="loan-details"><a>Hide</a></td>');
		hideLink.click(function() { toggle($(this)) });
		hideLink.insertBefore("td.loan-details");
	}
	$("tr").data("visible", "true");	// add our own data to each row in the table

	// Load the state of all the loans on the page
	// Collect all the loan IDs
	var loan_ids = [];
	var loan_rows = [];
	if(primary)	// The loan ID is in a different place on the two pages
	{
 		$("form#watch_form > table:nth-child(1) > tbody > tr").each(function(index) {
 			var id = $(this).attr("id").match(/[0-9]+/)[0];
 			loan_ids.push({loan_id: {N: id}});
 			loan_rows.push({id: id, row: $(this)});
 		});
	}
	else
	{
		$("tr").each(function(index) {
			var children = $(this).children("td");
			if (children.length > 0)
			{
				var id = children.first().next().children("p").first().text().match(/[0-9]+/)[0];
				loan_ids.push({loan_id: {N: id}});
				loan_rows.push({id: id, row: $(this)});
			}
		});
	}

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
	
	if(!primary) setTimeout(function() {
		console.log("re-enable listen");
		listenForChanges();
	}, 2000);
}
	
// Hides part of a row so it can't be clicked, and logs what was hidden to a DB
function toggle(source)
{
	console.log("toggle");
	if(!primary) dontListenForChanges();

	var row = source.parent();
	var details = row.children("td").first().next();
	var loan_tag = details.children("a").first();
	var loan_link = loan_tag.attr("href");
	var loan_description = loan_tag.text();
	var loan_id;
	if(primary)	loan_id = row.attr("id").match(/[0-9]+/)[0];
	else loan_id = details.children("p").first().text().match(/[0-9]+/)[0];
	
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
	if(!primary) setTimeout(function() {
		console.log("re-enable listen");
		listenForChanges();
	}, 2000);
}

// Hides the loan description in a certain row
function hide(row)
{
	// Now the details have been stored, we can hide it from view
	row.children("td").first().next().children("a").text("Hidden");
	row.children("td").first().next().children("a").css("color", "gray");
	row.children("td").first().children("a").text("Show");
	row.data("visible", "false");
}

// Reinstates the loan description in a certain row
function show(row, description)
{
	// Now the details have been stored, we can hide it from view
	row.children("td").first().next().children("a").text(description);
	row.children("td").first().next().children("a").("color", "rgb(9, 127, 201)");
	row.children("td").first().children("a").text("Hide");
	row.data("visible", "true");
}
