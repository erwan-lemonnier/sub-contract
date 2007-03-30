#-------------------------------------------------------------------
#
#   $Id: 07_test_error_messages.t,v 1.1 2007-03-30 08:38:50 erwan_lemonnier Exp $
#
#   070321 erwan Started
#

package main;

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;
use Data::Dumper;
use Carp qw(croak confess longmess);

BEGIN {

    use check_requirements;
    plan tests => 9;

    use_ok("Sub::Contract",'contract');
};

#------------------------------------------------------------
#
# test errors in condition code
#
#------------------------------------------------------------

sub foo {
    return 1;
}

sub _die {
    die "whatever";
}

# test die from a sub
my $c = contract('foo')
    ->invariant(\&_die)
    ->enable;

eval { foo(); };
ok($@ =~ /whatever at .*07_test_error_messages.t line 36/, "condition dies with correct error message (called sub)");

# test die called from contract def
$c->reset
    ->invariant(sub {
	die "enough!!";
    })
    ->enable;

eval { foo(); };
ok($@ =~ /enough!! at .*07_test_error_messages.t line 50/, "condition dies with correct error message (anonymous sub)");

# test croak
$c->reset
    ->invariant(sub {
	croak "croaking now";
    })
    ->enable;

eval { foo(); };
ok($@ =~ /croaking now at .*07_test_error_messages.t line 64/, "condition croaks with correct error message (anonymous sub)");

# test confess
$c->reset
    ->invariant(sub {
	confess "confessing now";
    })
    ->enable;

eval { foo(); };

TODO: {
    local $TODO = "correct confess's stack appearance";

    ok($@ =~ /confessing now at .*07_test_error_messages.t line/, "condition confesses with correct error message (anonymous sub)");
}

#------------------------------------------------------------
#
# test constraint failures
#
#------------------------------------------------------------

# invariant before
$c->reset->invariant( sub { return 0; } )->enable;
eval { foo(); };
ok($@ =~ /invariant fails before calling subroutine \[main::foo\] at .*07_test_error_messages.t line 90/, "invariant fails before");

# invariant after
my $count = 0;
$c->reset->invariant( sub { $count++; return $count != 1; } )->enable;
eval { foo(); };
ok($@ =~ /invariant fails before calling subroutine \[main::foo\] at .*07_test_error_messages.t line 96/, "invariant fails before");

# pre fails
$c->reset->pre( sub { return 0; } )->enable;
eval { foo(); };
ok($@ =~ /pre-condition fails before calling subroutine \[main::foo\] at .*07_test_error_messages.t line 101/, "pre condition fails");

# post fails
$c->reset->post( sub { return 0; } )->enable;
eval { foo(); };
ok($@ =~ /post-condition fails after calling subroutine \[main::foo\] at .*07_test_error_messages.t line 106/, "post condition fails");

# TODO: add more tests

