#-------------------------------------------------------------------
#
#   $Id: 05_test_results.t,v 1.1 2007-03-30 08:38:49 erwan_lemonnier Exp $
#
#   070321 erwan Started
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
    plan tests => 7;

    use_ok("Sub::Contract",'contract','results');
};


#
# test the condition code
#

my @want = (1,2,3);
my $c;
my @res;

sub foo { return @want; }

# test pre condition
eval { $c = contract('foo')
	   ->pre(
		 sub { my @results = results;
		       ok(!@results, "results returns nothing before function call");
		   }
		 )
	   ->enable;
   };
ok(!defined $@ || $@ eq '', "defined contract with 1 pre condition");

@res = foo();

# test post condition
eval { $c->reset()
	   ->post(
		 sub { my @results = results;
		       is_deeply(\@results,\@want,"check results after function call");
		   }
		 )
	   ->enable;
   };
ok(!defined $@ || $@ eq '', "re-defined contract with 1 post condition [$@]");

@want = (1,2,3);
@res = foo();

@want = [1,2,3];
@res = foo();

@want = "abc";
@res = foo();



