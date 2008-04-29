#-------------------------------------------------------------------
#
#   $Id: 09_test_too_many_args.t,v 1.1 2008-04-29 10:17:42 erwan_lemonnier Exp $
#

package main;

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;
use Data::Dumper;
use Carp qw(croak);

BEGIN {

    use check_requirements;
    plan tests => 26;

    use_ok("Sub::Contract",'contract');
};

my @res;

# functions to test
contract('foo_none')
    ->in()
    ->out()
    ->enable;

sub foo_none  { return @res; }

contract('foo_array')
    ->in(undef,undef)
    ->out(undef,undef)
    ->enable;

sub foo_array { return @res; }

contract('foo_hash')
    ->in(a => undef, b => undef)
    ->out(c => undef, d => undef)
    ->enable;

sub foo_hash  { return @res; }

contract('foo_mixed')
    ->in(undef,undef,a => undef, b => undef)
    ->out(undef,undef,c => undef, d => undef)
    ->enable;

sub foo_mixed { return @res; }

# test foo_none
eval { foo_none() };
ok(!defined $@ || $@ eq "", "foo_none no args");

eval { foo_none(12) };
ok($@ =~ /got too many input arguments/, "foo_none too many input arguments");

@res = (1,2);
eval { foo_none() };
ok(!defined $@ || $@ eq "", "foo_none with return values but void context");
eval { my $s = foo_none() };
ok($@ =~ /returned too many return values/, "foo_none too many return values (scalar context)");
eval { my @s = foo_none() };
ok($@ =~ /returned too many return values/, "foo_none too many return values (array context)");

# test foo_array
eval { foo_array(3,4) };
ok(!defined $@ || $@ eq "", "foo_array 2 input args");

eval { foo_array(1) };
ok(!defined $@ || $@ eq "", "foo_array 1 input arg");

eval { foo_array(3,4,6) };
ok($@ =~ /got too many input arguments/, "foo_array 3 input args");

@res = (1,2,3);
eval { foo_array() };
ok(!defined $@ || $@ eq "", "foo_array with 3 return values but void context");
eval { my $s = foo_array() };
ok(!defined $@ || $@ eq "", "foo_array with 3 return values but scalar context - ok in this particular case");
eval { my @s = foo_array() };
ok($@ =~ /returned too many return values/, "foo_array too many return values (array context)");

# test foo_hash
@res = (c => 1, d => 2);
eval { foo_hash(a => 1, b => 2) };
ok(!defined $@ || $@ eq "", "foo_hash 2 input hash args");

eval { foo_hash(a => 1, o => 2) };
ok($@ =~ /got too many input arguments/, "foo_hash too many input args");

eval { foo_hash(a => 1) };
ok(!defined $@ || $@ eq "", "foo_hash only 1 input arg");

@res = (c => 1, d => 2, p => 5);
eval { foo_none() };
ok(!defined $@ || $@ eq "", "foo_hash with 3 return values but void context");
eval { my $s = foo_hash() };
ok($@ =~ /odd number of hash-style return arguments/, "foo_hash with 3 return values but scalar context");
eval { my @s = foo_hash() };
ok($@ =~ /returned too many return values/, "foo_none too many return values (array context)");

# just to improve coverage:
eval { my $s = foo_hash(1,2,3) };
ok($@ =~ /odd number of hash-style input arguments/, "foo_hash with 3 input values but scalar context");

# test foo_mixed
@res = (0,1,c => 1, d => 2);
eval { foo_mixed(0,1,a => 1, b => 2) };
ok(!defined $@ || $@ eq "", "foo_mixed 4 input hash/list args");

eval { foo_mixed(0,1,a => 1, o => 2) };
ok($@ =~ /got too many input arguments/, "foo_mixed too many input args");

eval { foo_mixed(0,1,a => 1, o => 2,8) };
ok($@ =~ /odd number of hash-style input arguments/, "foo_mixed with 5 input values but scalar context");

eval { foo_mixed(a => 1) };
ok(!defined $@ || $@ eq "", "foo_mixed only 1 input arg");

@res = (1,2,c => 1, d => 2, p => 5);
eval { foo_mixed() };
ok(!defined $@ || $@ eq "", "foo_mixed with 8 return values but void context");
eval { my $s = foo_mixed() };
ok(!defined $@ || $@ eq "", "foo_mixed with 8 return values but scalar context - ok in that case");
eval { my @s = foo_mixed() };
ok($@ =~ /returned too many return values/, "foo_none too many return values (array context)");



