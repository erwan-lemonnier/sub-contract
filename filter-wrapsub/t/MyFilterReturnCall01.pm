package MyFilterReturnCall01;

use lib "../lib/", "t/", "lib/";
use Filter::WrapSubs;

sub import {
    new Filter::WrapSubs(caller(),1)
	->call_on_return('join','"-"')
}


1;
