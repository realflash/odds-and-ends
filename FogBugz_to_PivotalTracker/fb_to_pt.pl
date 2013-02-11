#!/usr/bin/perl -T

use strict;

my $in_file = $ARGV[0];
unless (-e $in_file)
{
	print STDERR "File $in_file does not exist\n";
}
unless (-f $in_file)
{
	print STDERR "File $in_file is not a regular file\n";
}
unless (-r $in_file)
{
	print STDERR "File $in_file exists but cannot be read. Permissions?\n";
}

open(IN, $in_file);						# open the file
my @lines = <IN>;						# read the whole file
close(IN);								# close the file
my $stories = {};						# hash ref to store all stories in
for(my $line_num = 1; $line_num <= scalar(@lines) - 1; $line_num++)
{
	my $story = {};						# hash ref to store details of the current story in
	my $line = $lines[$line_num];
	$line =~ s/^"//g;						# remove the leading "
	$line =~ s/"$//g;						# remove the trailing "
	my @fields = split('","', $line);		# split the line based on ","
	# FogBugz:         Category,Starred,Case,Area,Title,Remaining Time - Hours,Priority,Status,Assigned To"
	my $id = $fields[2];				# In order to sort the Stories roughly according to priority, the original ID cannot be kept, but we'll use it as a unique key for sorting
	my @text = split(" - ", $fields[4]);
	unless(scalar(@text) < 3)
	{
		print STDERR "Cannot determine title from description on line $line_num; too many instances of ' - '";
	}
	$story->{'title'} = $text[0];
	$story->{'description'} = $text[1];
	$story->{'labels'} = $fields[3];
	$story->{'story_type'} = lc($fields[0]);
	$story->{'estimate'} = -1;					# mine were all empty in this field, so I set to -1 for unestimated. You could compare the number of remaining hours in $fields[5]
												# and assign points on that basis
	$story->{'current_state'} = "unscheduled";	# puts everything in Icebox. You could set it on based on $fields[7];
	$story->{'requestor'} = "Ian Gibbs";
	$story->{'owner'} = "";						# mine were all inactive. You could set it based on $fields[8];
	$story->{'comment'} = "Imported from FogBugz; case number was $id";
	$story->{'priority'} = $fields[6];
	
	$stories->{$id} = $story;					# store this story
#	print ",".$story->{'title'}.",".$story->{'labels'}.",".$story->{'story_type'}.",".$story->{'estimate'}.",".$story->{'current_state'}.","
#			.$story->{'requestor'}.",".$story->{'owner'}.",".$story->{'description'}.",".$story->{'comment'}."\n";
}
# TODO more than 100 isn't accepted by Pivotal
my @sorted_ids = sort { $stories->{$a}->{'priority'} cmp $stories->{$b}->{'priority'} } keys %$stories;
print "Id,Story,Labels,Story Type,Estimate,Current State,Requested By,Owned By,Description,Comment\n";
foreach (@sorted_ids)
{
	my $story = $stories->{$_};
	print '"","'.$story->{'title'}.'","'.$story->{'labels'}.'","'.$story->{'story_type'}.'","'.$story->{'estimate'}.'","'.$story->{'current_state'}.'","'
			.$story->{'requestor'}.'","'.$story->{'owner'}.'","'.$story->{'description'}.'","'.$story->{'comment'}.'"'."\n";
}