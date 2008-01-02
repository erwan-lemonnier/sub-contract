#!/usr/local/bin/perl
#-------------------------------------------------------------------
#
#   $Id: test_top_bottom.pl,v 1.1 2008-01-02 12:36:34 erwan_lemonnier Exp $
#
#   070314 erwan Started
#

use strict;
use warnings;
use lib "../lib/", "t/", "lib/", ".";
use MyFilterTopBottom;
use Carp qw(confess);

# blabla
sub foo {
    my $l = "just some test";
    my $a = sub { 1; };
    1;
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

my $a = 2;
$a++;
