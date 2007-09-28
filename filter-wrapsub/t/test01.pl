#!/usr/local/bin/perl
#-------------------------------------------------------------------
#
#   $Id: test01.pl,v 1.1 2007-09-28 14:22:31 erwan_lemonnier Exp $
#
#   070314 erwan Started
#

use strict;
use warnings;
use lib "../lib/", "t/", "lib/", ".";
use MyFilter01;
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
