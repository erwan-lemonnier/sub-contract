#-------------------------------------------------------------------
#
#   $Id: 03_test_invariant.t,v 1.2 2008-01-02 14:38:39 erwan_lemonnier Exp $
#
#   070320 erwan Started
#

package My::Test;

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Sub::Contract qw(contract);

my $zoulou = 3;

sub foo {
    $zoulou = $_[0];
}

sub test_invariant {
    return $zoulou == 3;
}

package main;

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;
use Data::Dumper;

BEGIN {

    use check_requirements;
    plan tests => 4;

    use_ok("Sub::Contract",'contract');
};

contract('My::Test::foo')
    ->invariant(\&My::Test::test_invariant)
    ->enable;

eval { My::Test::foo(3) };
ok(!defined $@ || $@ eq "", "invariant passes");

eval { My::Test::foo(2) };
ok( $@ =~ /invariant fails after calling subroutine \[My::Test::foo\] at .*03_test_invariant.t line 48/, "invariant fails after");

eval { My::Test::foo(3) };
ok( $@ =~ /invariant fails before calling subroutine \[My::Test::foo\] at .*03_test_invariant.t line 51/, "invariant fails before");



