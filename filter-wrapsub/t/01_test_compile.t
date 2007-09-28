#-------------------------------------------------------------------
#
#   $Id: 01_test_compile.t,v 1.2 2007-09-28 14:22:31 erwan_lemonnier Exp $
#
#   070928 erwan Started
#

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;

BEGIN {

    use check_requirements;
    plan tests => 1;

    use_ok("Filter::WrapSubs");
};

