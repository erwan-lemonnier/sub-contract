#-------------------------------------------------------------------
#
#   $Id: 04_test_pre_post_conditions.t,v 1.1 2007-03-30 08:38:49 erwan_lemonnier Exp $
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
    plan tests => 10;

    use_ok("Sub::Contract",'contract');
};


#
# test the condition code
#

my @result = (1,2,3);
my $c;

sub foo {
    return @result;
}

# test pre condition
eval { $c = contract('foo')
	   ->pre(
		  sub {
		      croak "dying now" if ($_[0] eq 'please die');
		      return $_[0] eq 'bob';
		  }
		 )
	   ->enable;
   };
ok(!defined $@ || $@ eq '', "defined contract");

eval { foo('bob'); };
ok(!defined $@ || $@ eq "", "pre condition passes");

eval { foo('bilou') };
ok( $@ =~ /pre-condition fails before calling subroutine \[main::foo\] at .*04_test_pre_post_conditions.t/, "pre condition fails");

eval { foo('please die') };
ok( $@ =~ /dying now at .*04_test_pre_post_conditions.t/, "pre condition croaks");

# test post condition
eval {
    $c->pre(undef)
	->post(
	       sub {
		   croak "foo called in wrong context" if (!defined $Sub::Contract::wantarray || $Sub::Contract::wantarray != 1);
		   my @res = @Sub::Contract::result;
		   return $res[0] == 1
		   }
	       )
	->enable;
};
ok(!defined $@ || $@ eq '', "recompiled contract");

my @res;
eval { @res = foo('bilou'); };
ok(!defined $@ || $@ eq "", "pre condition now disabled and post condition ok");
is_deeply(\@res,[1,2,3], "foo returned [1,2,3]");

@result = (4,5,6);
eval { @res = foo('bilou'); };
ok($@ =~ /post-condition fails after calling subroutine \[main::foo\] at .*04_test_pre_post_conditions.t line/, "post condition failed");

my $res;
@result = (1,2);
eval { $res = foo('asldkfjbilou'); };
ok($@ =~ /foo called in wrong context at .*04_test_pre_post_conditions.t line/, "post condition croaks");


# TODO: try in non array context


# #
# # test argument passing
# #

# my $c;
# my @want;

# # pre
# sub pre { return @_; }

# eval { $c = contract('pre')
# 	   ->pre( sub {
# 	       if ($Sub::Contract::
# 	       is_deeply(\@_,\@want,                 "pre condition code got right arguments");
# 	       is_deeply(\@Sub::Contract::args,\@_,  "Sub::Contract::args contains the right value");
# 	       is_deeply(\@Sub::Contract::result,[], "Sub::Contract::result is empty");
# 	       is($Sub::Contract::wantarray, undef,  "Sub::Contract::wantarray args contains the right value");
# 	       return 1;
# 	   } )
# 	   ->enable;
#    };
# ok(!defined $@ || $@ eq '', "defined contract");

# @want = (5,6,7);
# pre(@want);

# @want = (['bob']);
# pre(@want);

# # post
# sub post { return @_; }

# eval { $c = contract('post')
# 	   ->post( sub { is_deeply(\@_,\@want,"post condition code got right arguments"); };
# 		   return 1;
# 		   )
# 	   ->enable;
#    };
# ok(!defined $@ || $@ eq '', "defined contract");

# @want = (5,6,7);
# my @res = post(@want);

# @want = (['bob']);
# @res = post(@want);

# # test it still works well in scalar context
# @want = (5,6,7);
# my $res = post(@want);

# @want = (['bob']);
# $res = post(@want);


# # post conditions should be skipped if called in no context...


# __END__




__END__

contract('My::Test::foo_pre')
    ->pre( sub { return $_[0] eq 'bob' } )
    ->enable;

eval { foo_pre('bob'); };
ok(!defined $@ || $@ eq "", "pre condition passes");

eval { pre_foo('bilou') };
ok( $@ =~ /subroutine pre-condition fails before calling subroutine \[main::pre_foo\] at .*04_test_pre_conditions.t/, "pre condition fails");



