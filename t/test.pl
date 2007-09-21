#-------------------------------------------------------------------
#
#   $Id: test.pl,v 1.1 2007-09-21 14:15:50 erwan_lemonnier Exp $
#
#   070314 erwan Started
#

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Sub::Contract;
use Sub::Contract::Pool;
use Carp qw(confess);

# blabla
sub foo {
    my $l = "just some test";
    my $a = sub { 1; };
    confess "died!";
}

sub bar {}

sub toto ($) {
    my $bob = shift;

    if ($bob) {
	return "blob";
    } else {
	if (1) {
	    return sub { "bib!" };
	}
    }

    return
}

foo();

print "stuff\n";
