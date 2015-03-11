var http = require('http');
var fs = require('fs');
var cheerio = require('cheerio');
var exec = require('child_process').exec;
var nodemailer = require('nodemailer');

var domain = 'freepostcodelottery.com';
var userid = '';
var from_email = '';
var to_email = '';

var temp_image = 'temp.png'
var result_image = 'result.png'

var html = '';
var image_uri = '';
http.get({host: domain, headers: { Cookie: ['userId=' + userid], }, path: '/'}, function(res) {
	res.on('data', function(data) {
        // collect the data chunks to the variable named "html"
        html += data;
    }).on('end', get_image)});

function get_image()
{
		$ = cheerio.load(html);
		var title = $('title').text();
		image_uri = $('#winning-result > span > img').attr('src');
		http.get({host: domain, headers: { Cookie: ['userId=' + userid], }, path: image_uri}, function(res) {
			res.pipe(fs.createWriteStream(temp_image));
		});
		
		exec('convert ' + temp_image + ' -fill black -opaque white -crop 190x35+13+1 ' + result_image, function (error, stdout, stderr) {});
		
// create reusable transporter object using SMTP transport
var transporter = nodemailer.createTransport({
	port: 25,
	secure: false,
	ignoreTLS: true,
});

// setup e-mail data with unicode symbols
var mailOptions = {
    from: from_email, // sender address
    to: to_email, // list of receivers
    subject: 'FPL result', // Subject line
    text: 'Today\'s result', // plaintext body
    attachments: [{path: result_image}]
};

// send mail with defined transport object
transporter.sendMail(mailOptions, function(error, info){
    if(error){
        console.log(error);
    }else{
        console.log('Message sent: ' + info.response);
    }
});
}

