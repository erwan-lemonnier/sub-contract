package MyFilterTopBottom;

# test only insert_top

use lib "../lib/", "t/", "lib/";
use Filter::WrapSubs;

sub import {
    new Filter::WrapSubs(caller(),1)
	->insert_top('print "start!\n"')
	->insert_bottom('print "end!\n"');
}


1;
