var https = require('https');
var cheerio = require('cheerio');
var encoder = require('urlcode-json');
var cookie = require('cookie-client');

var html = '';
var cookie_store = cookie();
var data = encoder.encode( { 
	"signin[username]": "zoe@flash.org.uk",
	"signin[password]": "1Timeatbandcamp",
	"signin[_csrf_token]": "2fbe0fc73dfa9ddf927bc0c52e7a3013",
} , true );
data = "client_id=&redirect_uri=&state=&response_type=&signin%5B_csrf_token%5D=2fbe0fc73dfa9ddf927bc0c52e7a3013&signin%5Busername%5D=zoe%40flash.org.uk&signin%5Bpassword%5D=1Timeatbandcamp"


https.get({host: 'www.fundingcircle.com', path: '/login'}, function(res) {
	cookie_store.addFromHeaders(res.headers);
    res.on('data', function(data) {
        // collect the data chunks to the variable named "html"
        html += data;
    }).on('end', login)});

function login()
{
		$ = cheerio.load(html);
		var title = $('title').text();
		console.log('A: Get log in page');
		var token = $('input#signin__csrf_token').attr('value');
		var token_field = $('input#signin__csrf_token').attr('name');
		var username_field = $('input#email').attr('name');
		var password_field = $('input#password').attr('name');
		
		console.log('B: Attempt log in');
		var data = {
			client_id: '',
			redirect_uri: '',
			state: '',
			response_type:'',
		};
		data[username_field] = 'zoe@flash.org.uk';
		data[password_field] = '1Timeatbandcamp';
		data[token_field] = token;
		var data_string = encoder.encode(data, true );
		console.log(data_string);
	
		var login_options = {
			headers: { Cookie: cookie_store.cookieStringForRequest('fundingcircle.com', '/', true), },
			host: 'www.fundingcircle.com',
			path: '/login',
			method: 'POST',
		}
		
/*		var req = https.request(login_options, function(res)
		{
			console.log("statusCode: ", res.statusCode);
			console.log("headers: ", res.headers);
			res.on('data', function(d)
			{
				process.stdout.write(d);
			});
		});
		req.end(data_string);
		req.on('error', function(e)
		{
			console.error(e);
		}); */
}

