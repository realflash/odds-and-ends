Address Bot
===========

# General
Retrieves up to 999 users from the Azure AD Graph API and checks their mobilde phone and fax fields to make sure they are filled out fully and properly. It's a mild example of how to access the Azure AD Graph API from perl.

# Installationa of prerequisites (on CentOS)
yum -y install git perl-Log-Log4perl perl-Moo perl-YAML cpanm
git clone https://github.com/mschilli/oauth-cmdline.git
cd oauth-cmdline
perl Makefile.pl
make
make install
cpanm Mojo::Base

# Setup
* Set up a temporary web service for callbacks as described in the docs for OAuth::Cmdline
* Sign up for Azure AD for your Office 365 (free).
* Add an Azure AD app of type Web, with callbacks pointing to your temporary web service
* Retrieve the ID and key (secret) from the app page
* Update your web service with the ID and secret and start it
* Go to your web service and follow the link
* Authenticate to O365
* Update the address bot code with correct parameters and run it on the same box where you ran the web service
 
 Remember the token is tied to the user account - if the user account is removed or disabled, address bot will stop working.

# Run

Just run it. No parameters required. 
