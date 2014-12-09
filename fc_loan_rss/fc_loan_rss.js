var https = require('http');
var cheerio = require('cheerio');
var encoder = require('urlcode-json');
var cookie = require('cookie');

var html = '';
var headers;

/*var data = encoder.encode( { 
	"signin[username]": "zoe@flash.org.uk",
	"signin[password]": "1Timeatbandcamp",
	"signin[_csrf_token]": "2fbe0fc73dfa9ddf927bc0c52e7a3013",
} , true );
data = "client_id=&redirect_uri=&state=&response_type=&signin%5B_csrf_token%5D=2fbe0fc73dfa9ddf927bc0c52e7a3013&signin%5Busername%5D=zoe%40flash.org.uk&signin%5Bpassword%5D=1Timeatbandcamp"
*/

https.get({host: 'www.fundingcircle.com', path: '/login'}, function(res) {
//	headers = res.headers;
    res.on('data', function(data) {
        // collect the data chunks to the variable named "html"
        html += data;
    }).on('end', login)});

function login()
{
		$ = cheerio.load(html);
		var title = $('title').text();
		console.log(title);
}

/*var login_options = {
	headers: { Cookie: "optimizelyEndUserId=oeu1417582586093r0.9809304306989266; funding_circle=a420e0eb243d410533b18ff64b2153245ef9582c69d2e7de8f81a6e095135ada804d2a0afb08e5e0dcb169278ccd52f6f73ed947b7ff35b603d080f762581f65:390da2a1d92e5b9a2d7de876ccc6be74623dd0ab893c7cb254a1f70ff85395c921b175fd46f2c5dfcf6d96936953fe0b383ace4b081d49d57291942be3f468e7; optimizelySegments=%7B%22315524136%22%3A%22direct%22%2C%22315524137%22%3A%22ff%22%2C%22315536086%22%3A%22false%22%7D; optimizelyBuckets=%7B%7D; __utma=74436741.1571850279.1417582594.1417582594.1417582594.1; __utmc=74436741; __utmz=74436741.1417582594.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none); _ga=GA1.2.1571850279.1417582594", },
	host: 'www.fundingcircle.com',
	path: '/login',
	method: 'POST',
}
var req = https.request(login_options, function(res) {
  console.log("statusCode: ", res.statusCode);
  console.log("headers: ", res.headers);

  res.on('data', function(d) {
    //process.stdout.write(d);
  });
});
req.write(data);
req.end();
req.on('error', function(e) {
  console.error(e);
});*/