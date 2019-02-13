#!/usr/bin/perl

use strict;
use open qw/:std :utf8/;	# tell perl that stdout, stdin and stderr is in utf8
use Error qw(:try);
use Log::Log4perl qw(:easy);
use Data::Dumper;
use Attono::Utils;
use Attono::Car;
use Attono::ChannelList;
use Attono::AdvertChannel::Channel;
use Getopt::Long;
use File::Basename;
use File::Spec;

my $data_dir = "/home/igibbs/Dropbox/Work/Attono/operations/orders/vehicles";
my $channels_file = "$data_dir/channels.xml";
my $log_file = "$data_dir/fb_group_mapper.log4j";

# Init logging
Log::Log4perl->init($log_file);
my $log = Log::Log4perl->get_logger('main');

my $xml = undef;
GetOptions ('xml|x=s' => \$xml);

use constant
{
	ERR_NO_INPUT_FILE_SPECIFIED => 1,
	ERR_READING_INPUT_FILE => 2,
};

# ---- MAIN ----

if(!defined($xml))
{
		&printHelp;
		exit ERR_NO_INPUT_FILE_SPECIFIED;
} 

$log->info("Input XML\t".$xml); 

# Load the advert channels
$log->info("Loading channels");
my($filename, $xml_dir, $suffix) = fileparse($xml);
Attono::Utils->testDirectoryReadable(File::Spec->rel2abs($xml_dir));
my $channels = Attono::ChannelList->new(file => $channels_file, data_dir => $data_dir, resource_dir => File::Spec->rel2abs($xml_dir));



exit 0;

sub printHelp
{
	print STDERR "Usage: ./post-new.pl --xml <channel-xml-file>
";
}
