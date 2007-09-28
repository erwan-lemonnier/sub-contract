#-------------------------------------------------------------------
#
#   $Id: 02_test_wrapsubs.t,v 1.2 2007-09-28 15:15:54 erwan_lemonnier Exp $
#
#   070928 erwan Started
#

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;

BEGIN {
    use check_requirements;
    plan tests => 2;
};

my @TESTS = (
	     'test01.pl' => 'result01.txt',
	     'test_return01.pl' => 'result_return01.txt',
	     );

# where are we running from?
my $path = "";
if (-e "./02_test_wrapsubs.t") {
    $path = ".";
} elsif (-e "./t/02_test_wrapsubs.t") {
    $path = "./t";
}

while (@TESTS) {
    my $prog   = $path."/".(shift @TESTS);
    my $source = $path."/".(shift @TESTS);

    # we do the diff between files manually, in order to
    # see exactly where they differ

    my $diff = 0;
    my $line = 0;

    open(RUN,"perl $prog |") or die "ERROR: failed to run perl $prog: $!";
    open(SOURCE,$source) or die "ERROR: failed to read file $source: $!";

    while (1) {
	my $got = <RUN>;
	my $want = <SOURCE>;
	my $line++;

	if (!defined $got && !defined $want) {
	    last;
	}

	if (!defined $got || !defined $want) {
	    $diff = 1;
	    print "# differ at line $line:\n";
	    print "# [".((defined $got)?$got:"")."]\n";
	    print "# [".((defined $want)?$want:"")."]\n";
	    last;
	}

	# PPI does some magic with tabs, so we want them gone
	$got =~ s/^(\s+)//gm;
	$want =~ s/^(\s+)//gm;

	if ($got ne $want) {
	    $diff = 1;
	    chomp $got; chomp $want;
	    print "# differ at line $line:\n";
	    print "# [$got]\n";
	    print "# [$want]\n";
	    last;
	}
    }

    close(RUN);
    close(RUN);

    ok($diff == 0,"filtered $prog");
}

