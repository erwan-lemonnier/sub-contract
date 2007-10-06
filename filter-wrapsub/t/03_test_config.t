#-------------------------------------------------------------------
#
#   $Id: 03_test_config.t,v 1.2 2007-10-06 22:11:09 erwan_lemonnier Exp $
#
#   070928 erwan Started
#

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;

BEGIN {

    use check_requirements;
    plan tests => 11;

    use_ok("Filter::WrapSubs");
};

my $f = new Filter::WrapSubs('main');

foreach my $attribute ('insert_top','insert_bottom','insert_before_return') {
    is($f->$attribute, undef, "->$attribute is undef by default");
    $f->$attribute("string");
    # TODO: test validate
    is($f->$attribute, "string", "->$attribute set to string");
    # TODO: test with coderef
    # TODO: test with other types and see that validate fails
}

# TODO: same tests with call_on_return
is($f->call_on_return, 0, "->call_on_return is 0 by default in scalar context");
my @res = $f->call_on_return;
is_deeply(\@res, [], "->call_on_return is () by default in array context");

$f->call_on_return("string");
@res = $f->call_on_return;
is_deeply(\@res, ["string"], "->call_on_return set to list");

$f->call_on_return(1,2,3);
@res = $f->call_on_return;
is_deeply(\@res, [1,2,3], "->call_on_return set to list");
