#!/usr/bin/perl

use strict;
use open qw/:std :utf8/;	# tell perl that stdout, stdin and stderr is in utf8
use Error qw(:try);
use Log::Log4perl qw(:easy);
use Data::Dumper;
use Attono::Utils;
use Attono::AdvertChannel::FacebookGroup;
use Selenium::Chrome;
use File::Basename;
use File::Spec;
use Date::Manip;

my $log_file = "group_manager.log4j";
my $browser_profile = "/home/igibbs/.config/google-chrome/Selenium";
my $group_url = "https://www.facebook.com/groups/447426502066200/";

# Init logging
Log::Log4perl->init($log_file);
my $log = Log::Log4perl->get_logger('main');

# Start a browser
Attono::Utils->testDirectoryReadable($browser_profile);
$log->info("Start browser");
my $browser = Selenium::Chrome->new('extra_capabilities' => 
		{ 'chromeOptions' => { 'args' => ["user-data-dir=$browser_profile"]}});

$log->debug("Going to group url");
my $channel = Attono::AdvertChannel::FacebookGroup->new(browser => $browser, post_url => $group_url);
$browser->get($channel->post_url);
my $posts = $channel->findElementsSafe('//div[@aria-label=\'Story\']', 'xpath');

#print Dumper $posts;
$log->debug("Found ".scalar(@$posts)." posts");

my $date = dateLastPost($$posts[scalar(@$posts)-1]);
#Attono::AdvertChannel::Channel->findElementSafe('//div[/div/div/div/div/div/div/div/div/span/span/a]', 'xpath');

exit 0;

sub dateLastPost()
{
	my $post = shift;
	
	my $date_element = $channel->findElementSafe('//div/div/div/div/div/div/div/div/div/span/span/a/abbr', 'xpath');
	my $epoch = $date_element->get_attribute('data-utime');
	my $date = Date::Manip::Date->new($epoch);
	$log->debug("Last post on page timed at ".$date->printf('%O'));
}