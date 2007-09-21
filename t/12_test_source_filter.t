#-------------------------------------------------------------------
#
#   $Id: 12_test_source_filter.t,v 1.1 2007-09-21 00:16:47 erwan_lemonnier Exp $
#
#   070921 erwan Started
#

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Data::Dumper;
use Carp qw(croak);
use Test::More;

BEGIN {

    use check_requirements;
    plan tests => 91;

    use_ok("Sub::Contract::SourceFilter");
};

# check argument parsing in new()
eval { new Sub::Contract::SourceFilter; };
ok($@ =~ /BUG: no caller provided/, "new without args dies");

# hijack filter_add and filter_read and
# feed the source filter with a number of packages

sub test_filter {
    my ($name,$in,$out) = @_;

    no strict 'refs';
    no warnings 'redefine';

    *{ "Sub::Contract::SourceFilter::filter_add" } = sub ($) {};
#    *{ "Sub::Contract::SourceFilter::filter_add" } = sub {};

    my $filter = new Sub::Contract::SourceFilter('pkg1');
    my $line;
    
    *{ "Sub::Contract::SourceFilter::filter_read" } = sub (;$) {
#    *{ "Sub::Contract::SourceFilter::filter_read" } = sub {
	print "filter_read called. returning [$line]\n";
	return 0 if (!defined $line);
	$_ = $line; 
	return 1;
    };

    use strict 'refs';
    use warnings 'redefine';

    for my $l (split(/\n/,$in)) {
	$line = $l;
	print "line is [$line]\n";
	$filter->filter();
    }

    $line = undef;
    $filter->filter();
}

test_filter('pkg1',
	    join("\n",
		 "package blabla;",
		 "sub foo {",
		 "    return bar;".
		 "}",
		 "1;"),
	    "");
	    


