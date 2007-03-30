#-------------------------------------------------------------------
#
#   $Id: 01_test_compile.t,v 1.1 2007-03-30 08:38:49 erwan_lemonnier Exp $
#
#   070314 erwan Started
#

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;

BEGIN {

    use check_requirements;
    plan tests => 5;

    use_ok("Sub::Contract::Pool");
    use_ok("Sub::Contract::ArgValidator");
    use_ok("Sub::Contract::Memoizer");
    use_ok("Sub::Contract::Compiler");
    use_ok("Sub::Contract");
};

