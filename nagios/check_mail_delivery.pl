#!/usr/bin/perl

# Public domain
# Sends an email to an mailman list via an exim server, and expects to find
# That email in its mailbox later

use Mail::Box::Manager;
use Mail::Transport::Exim;
use Data::UUID;
use Nagios::Plugin;

my $mailbox_dir = '/var/lib/nagios/Maildir';

my $np = Nagios::Plugin->new;

# Generate an email and send it to myself via Exim
my $du = Data::UUID->new();
my $uuid = $du->create();
my $uuid_string = $du->to_string($uuid);
my $sender = Mail::Transport::Exim->new();
my $body = Mail::Message::Body->new(data => 'Test message');
my $head = Mail::Message::Head->build(From => 'nagios@flash.org.uk', To => 'monitoring@flash.org.uk', Subject => $uuid_string);
my $message = Mail::Message->new(body => $body, head => $head);
my $res = $sender->send($message) || $np->nagios_exit(CRITICAL, "Failed to send email");
if(!$res)
{
	$np->nagios_exit(CRITICAL, "Failed to send email");
}

# Wait for it to be delivered
sleep 3;

# See if it's there
my $mgr    = Mail::Box::Manager->new;
my $mailbox = $mgr->open('/var/lib/nagios/Maildir');
#my $inbox = $mgr->open({create => 0, folder => 'inbox', folderdir => $mailbox_dir, type => 'maildir' });
#my $trash = $mgr->open({create => 1, folder => 'Trash', folderdir => $mailbox_dir, type => 'maildir' });
#exit 0;
my @messages = $mailbox->messages();
my $found = 0;
foreach my $message ($mailbox->messages)
{
	if($message->get('Subject') =~ /${uuid_string}/)
	{
		$found = 1;
		unlink($message->filename());
		last;
	}
}
$mailbox->close(write => 'NEVER');

if($found)
{
	$np->nagios_exit(OK, "Sent message found in my mailbox");
}
else
{
	$np->nagios_exit(CRITICAL, "Sent message not found in my mailbox");
}
