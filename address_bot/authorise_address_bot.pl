#!/usr/bin/perl -w

use strict;
use OAuth::Cmdline;
use OAuth::Cmdline::Mojo;

my $listen_uri = "http://10.0.1.123:8080"; 		# What local interface to listen on
my $local_uri = "http://server.example.com:8080";	# What DNS name to connect to to reach this service - useful if IP above is not directly reachable due to NAT etc.
my $client_id = "ce6dcddd-8258-42cb-909c-58bd34532ae2"; # FAKE EXAMPLE - get from Azure AD apps page
my $client_secret = "MUYsfLylEm3BhugiYieZhryfgnOQoAVQdlZ3sy5pz4I="; 	# FAKE EXAMPLE - get from Azure AD apps page

my $oauth = OAuth::Cmdline->new( site => "azure-ad", client_id => $client_id, login_uri => "https://login.microsoftonline.com/common/oauth2/authorize",
				token_uri => "https://login.microsoftonline.com/common/oauth2/token", local_uri => $local_uri, client_secret => $client_secret );

my $app = OAuth::Cmdline::Mojo->new(
    oauth => $oauth,
);
 
$app->start( 'daemon', '-l', $listen_uri );

