#!/usr/bin/perl
use strict;
use warnings;
use DBI;

# Set these for your situation
my $MTDIR = "/home/cmowner/CoffeeMud";
my $BACKUPDIR = "/home/cmowner/backups";
my $VERSION = "1.0.0";
my $OPTION_FILE = "/root/.exportrc";
my $MYSQLUSER = "";
my $MYSQLPSWD = "";
my $TABLEPREFIX = "";
my $MYOUTPUT = "/root/MemberList.txt";

sub ReadPrefs
{
	my $LineCount = 0;
	open(my $fh, '<:encoding(UTF-8)', $OPTION_FILE)
		or die "Could not open file '$OPTION_FILE' $!";

	while (my $row = <$fh>)
	{
		chomp $row;
		if ($LineCount == 0)
		{
			$MYSQLUSER = $row;
		}
		if ($LineCount == 1)
		{
			$MYSQLPSWD = $row;
		}
		if ($LineCount == 2)
		{
			$TABLEPREFIX = $row;
		}
		$LineCount += 1;
	}
	close($fh);
	# print "User = $MYSQLUSER, PSWD = $MYSQLPSWD\n";
}


if (! -f $OPTION_FILE)
{
	print "Unable to open '$OPTION_FILE'. Please create it with your mysql data in this format:\n";
	print "First line - mysql user\nSecond line = mysql-password\nThird line = table prefix\n";
	print "--- Press Enter To Continue: ";
	my $entered = <STDIN>;
	exit 0;
}
ReadPrefs();

#-------------------
# No changes below here...
#-------------------

print "exportmembers.pl version $VERSION\n";
print "==============================\n";

# Connect to the database.
my $dbh = DBI->connect("DBI:mysql:database=joomla;host=localhost",
                       $MYSQLUSER, $MYSQLPSWD,
                       {'RaiseError' => 1});

my $table = $TABLEPREFIX."_osmembership_field_value";

# print "table = '$table'\n";

# now retrieve data from the table.
my $sth = $dbh->prepare("SELECT * FROM $table");
$sth->execute();
my $curuser = "";
open(OUTFH, '>', $MYOUTPUT) or die $!;
while (my $ref = $sth->fetchrow_hashref())
{
	# print "Found a row: id = $ref->{'id'}, subscriber = $ref->{'subscriber_id'} name = $ref->{'field_value'}\n";
	if ($ref->{'subscriber_id'} ne $curuser)
	{
		$curuser = $ref->{'subscriber_id'};
	}
	if ($ref->{'field_id'} == 31)
	{
		my $EmailAddress = $ref->{'field_value'};
		print "Saw curuser = $curuser at $EmailAddress\n";
		if(index($EmailAddress, "\@") == -1)
		{
			print "Was not a address\n";
			next;
		}
		print (OUTFH "$EmailAddress\n");
	}
}
$sth->finish();

# Disconnect from the database.
$dbh->disconnect();
close(OUTFH);
exit 0;
