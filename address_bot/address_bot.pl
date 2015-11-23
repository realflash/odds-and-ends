#!/usr/bin/perl -w

use strict;
use OAuth::Cmdline;
use LWP::UserAgent;
use JSON;
#use Data::Dumper;							# Generally useful
#use Text::TabularDisplay;						# Useful for dumping the contents of user entries to the console
use Net::DNS;
use Mail::Sender;
#use open qw/:std :utf8/;						# Enable UTF-8 output if you're printing stuff to the console

# ==== STUFF YOU CAN UPDATE ====
my $domain = "example.com";
my $client_id = "ce6dcddd-8258-42cb4-9045-5erd16132ae2";		# Retrieved from the Azure AD Applications page - this is a fake value
my $client_secret = "MUYsfjylEm3fhugiYieZ5zVVDnOQofVQdlZ3sy5pz4I=";	# Retrieved from the Azure AD Applications page - this is a fake value
my $filters = ['Adam Armstrong', 'Becky Bailey', 'Migration Director'];	# An array of regexes that will be case-insensitively matched against the displayName of an entry and skipped
my $address_master = "postmaster\@$domain";				# Who gets emailed a weekly summary email of how complete the address book is
my $helo_name = "server.$domain";						# What the mailer announces itself as when connecting to the SMTP server
									# Make sure this is an FQDN that can be forward and reverse looked up to get past spam filters

# ==== STUFF YOU CAN'T UPDATE ====
my $graph_url = "https://graph.windows.net/$domain";
my $api_version = "api-version=1.6";

# ---- Prototypes ----
sub printUsers($);
sub sendEmailToBadUser($);
sub sendSummaryEmail($$);
sub getMXServer();
sub sendEmail($$$);

# ---- MAIN ----
my $oauth = OAuth::Cmdline->new( site => "azure-ad", client_id => $client_id, login_uri => "https://login.microsoftonline.com/common/oauth2/authorize",
				token_uri => "https://login.microsoftonline.com/common/oauth2/token", local_uri => "http://ldap.$domain:8080", client_secret => $client_secret );
print "Getting destination mail server...";
my $mx = getMXServer();
print "done\n";
my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;
 
print "Retrieving user data...";
my $response = $ua->get( "$graph_url/users?$api_version&\$top=999", $oauth->authorization_headers );
unless($response->is_success)
{
	die $response->status_line;
}
print "done\n";

print "Processing user data...";
my $response_object = from_json($response->decoded_content);  # or whatever
my $users = $response_object->{'value'};

my $filtered_users = [];
my $no_email_users = [];
foreach my $user (@$users)
{
	# Users with no email address have had their mailbox removed but not their AD account. Off-boarded improperly
	if(!defined($user->{'mail'}))
	{
		push(@$no_email_users, $user);
		next;
	}

	# Users with no givenName are rooms or DLs
	next unless(defined($user->{'givenName'}));

	# Users in the above fileterlist should be ignored
	my $ignore = 0;
	my $displayName = $user->{'displayName'}; $displayName = "" unless defined($displayName);
	foreach my $filter (@$filters)
	{
		if ($displayName =~ /$filter/i)
		{
			$ignore = 1;
			last;
		}
	}
	next if($ignore);
	push(@$filtered_users, $user);
}
print "done\n";

# Check the remaining entries for completeness
print "Emailing users...";
my $bad_count = 0;
foreach my $user (@$filtered_users)
{
	my $mobile = $user->{'mobile'}; $mobile = "" if ! defined($mobile);
	my $fax = $user->{'facsimileTelephoneNumber'}; $fax = "" if ! defined($fax);
	my $messages = [];
	my $bad = 0;

	# Check mobile field
	if(length($mobile) < 12)
	{
		push (@$messages, "Mobile (cell) number too short. Must be at least 12 characters (e.g. +16503456789)");
		$bad = 1;
	}
	else
	{
		if($mobile !~ /^\+/)
		{
			push (@$messages, "Mobile (cell) number not in international format. Must start with + and then country code (e.g. +44, +1)");
			$bad = 1;
			
		}
		if($mobile !~ /[0-9\.+()\- ]{12,}/)
		{
			push (@$messages, "Mobile (cell) number doesn't contain a telephone number. Must contain at least 11 digits)");
			$bad = 1;
		}
	}

	# Check fax (Skype) field
	if(length($fax) < 2)
	{
		push (@$messages, "Skype ID (in Fax field (NOT Business Fax field)) too short. Must be at least 2 characters");
		$bad = 1;
	}

	if($bad)
	{
		$bad_count++;
		$user->{'messages'} = $messages;
		sendEmailToBadUser($user);
	}
}
print "done\n";

print "Sending summary...";
my $total_users = scalar(@$filtered_users);
sendSummaryEmail($bad_count, $total_users);
print "done\n";

exit 0;

# ---- Functions ----

sub sendEmail($$$)
{
	my $recipient = shift;
	my $subject = shift;
	my $msg = shift;

	my $sender = new Mail::Sender({smtp => $mx, from => "addressbot\@$domain", to => $recipient, subject => $subject, on_errors => 'die', client => $helo_name,
					ctype => "text/html", charset => "UTF-8"});
	$sender->Open({encoding => "Quoted-printable"});
	$sender->SendEnc($msg);
	$sender->Close();
}

sub getMXServer()
{
	my $resolver = new Net::DNS::Resolver();
	my $reply = $resolver->query( $domain, 'MX' );
	
	my $result =  $reply->{'answer'}[0]->{'exchange'};

	my $mx = "";
	foreach my $part (@{$result->{'label'}})
	{
		unless($mx eq "") { $mx = "$mx." };
		$mx = $mx.$part;
	}
	foreach my $part (@{$result->{'origin'}->{'label'}})
	{
		unless($mx eq "") { $mx = "$mx." };
		$mx = $mx.$part;
	}

	return $mx;
}

sub sendSummaryEmail($$)
{
	my $bad = shift;
	my $total = shift;

	sendEmail($address_master, "Address Bot weekly summary", "$bad/$total users have incomplete address book entries. Ol\x{00E9}!\n");
}

sub sendEmailToBadUser($)
{
	my $user = shift;

#	if($user->{'displayName'} =~ /Gibbs/)
#	{	
		my $msg = "<html>
<head/>
<body>
<table width=\"600\">
<tr>
<td>
Dear $user->{'displayName'},<br/>

<p>If you're new to the company, welcome. I'm emailing you to ask you to fill out your entry in our Global Address Book. This is so that your colleagues can easily get hold of you. I've checked your entry, and it has these problems:
<ul>";
		foreach my $message (@{$user->{'messages'}})
		{
			$msg = "$msg<li>$message</li>\n";
		}
		$msg = "$msg</ul>

<p>You can update your entry in the address book by visiting <a href=\"https://outlook.office365.com\">https://outlook.office365.com</a>. Click the gear icon, and click Options. Then click General > My account . Due to some shortcomings in the Office 365 interface, it is possible to put it in the wrong place (and it will then not filter through to the address book).</p>

<p>Address Bot.</p>

<p>P.S. I am a bot, but you can reply to me and a human will get back to you.</p>
</td>
</tr>
</table>
</body>
</html>";
		sendEmail($user->{'mail'}, "Please update your address book entry", $msg);
#	}
}

sub printUsers($)
{
	my $users = shift;

	my $table = Text::TabularDisplay->new(("Display name", "First name", "Surname", "Email", "Fax", "Mobile", "Messages"));
	foreach my $user (@$users)
	{
		$table->add(($user->{'displayName'}, $user->{'givenName'}, $user->{'surname'}, $user->{'mail'}, $user->{'facsimileTelephoneNumber'}, $user->{'mobile'}, $user->{'messages'}));
	}

	print $table->render."\n";
}

sub stringifyList
{
	my $list = shift;

	my $r = "";
	foreach my $v (@$list)
	{
		$r = $r."$v ";
	}

	return $r;
}
