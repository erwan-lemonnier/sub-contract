#!/usr/bin/perl
use strict;
use warnings;
use lib "lib/";
require Sub::Contract;

my $tag = "VERSION_".$Sub::Contract::VERSION;
$tag =~ s/\.//;
print "-> tagging files with tag [$tag]\n";

`cat MANIFEST | grep -v MANIFEST | grep -v META.yml | xargs cvs tag $tag`;

