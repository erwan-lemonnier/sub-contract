#-------------------------------------------------------------------
#
#   $Id: 03_test_config.t,v 1.1 2007-09-29 06:12:38 erwan_lemonnier Exp $
#
#   070928 erwan Started
#

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;

BEGIN {

    use check_requirements;
    plan tests => 7;

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
