package MyFilterReturn01;

use lib "../lib/", "t/", "lib/";
use Filter::WrapSubs;

sub import {
    new Filter::WrapSubs(caller(),1)
	->insert_before_return('print "bob!\n"')
}


1;
