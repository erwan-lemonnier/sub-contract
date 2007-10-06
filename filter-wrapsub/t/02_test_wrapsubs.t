#-------------------------------------------------------------------
#
#   $Id: 02_test_wrapsubs.t,v 1.3 2007-10-06 06:08:28 erwan_lemonnier Exp $
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

# test files to filter
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
    my $file = $path."/".(shift @TESTS);
    my $want = $path."/".(shift @TESTS);

    # we do the diff between files manually, in order to
    # see exactly where they differ

    my $diff = 0;
    my $line = 0;

    open(RUN,"perl $file |") or die "ERROR: failed to run perl $file: $!";
    open(WANT,$want) or die "ERROR: failed to read file $want: $!";

    while (1) {
	my $got = <RUN>;
	my $expect = <WANT>;
	$line++;

	if (!defined $got && !defined $expect) {
	    last;

	} elsif (!defined $got || !defined $expect) {
	    $diff = 1;
	    print "# differ at line $line:\n";
	    print "# [".((defined $got)?$got:"*undef*")."]\n";
	    print "# [".((defined $expect)?$expect:"*undef*")."]\n";
	    last;

	} else {
	    # PPI does some magic with tabs, so we want them gone
	    $got =~ s/^(\s+)//gm;
	    $expect =~ s/^(\s+)//gm;

	    if ($got ne $expect) {
		$diff = 1;
		chomp $got; chomp $expect;
		print "# differ at line $line:\n";
		print "# [$got]\n";
		print "# [$expect]\n";
		last;
	    }
	}
    }

    close(RUN);
    close(WANT);

    ok($diff == 0,"filtered $file");
}

