use strict;
use warnings;
use lib "../lib/", "t/", "lib/", ".";
use MyFilterReturn01;
use Carp qw(confess);

# return nothing
sub foo_nop1 {
    return
}

sub foo_nop2 { return }

sub foo_nop3 {
    return;
}

sub foo_nop4 { return; }

# return scalars
sub foo_scalar1 {
    return 1;
}

sub foo_scalar2 { return 1; }

sub foo_scalar3 {
    return $a;
}

sub foo_scalar4 { return $a; }

# return lists
sub foo_list1 {
    return ()
}

sub foo_list2 { return () }

sub foo_list3 {
    return (1);
}

sub foo_list4 { return (1); }

sub foo_list5 {
    return (1,2,$a);
}

sub foo_list6 { return (1,2,$a); }

# return hash
sub foo_hash1 {
    return (a => 1, b=> 2);
}

sub foo_hash2 { return (a => 1, b=> 2) }

sub foo_hash3 {
    return (a => 1, b=> 2);
}

sub foo_hash4 { return (a => 1, b=> 2); }

# return array ref
sub foo_aref1 {
    # blabla
    return [ a => 1, b=> 2 ];
}

sub foo_aref2 { return [ a => 1, b=> 2 ]; }

sub foo_aref3 {
    my $a = shift @_;
    return [ a => $a, b=> 2 ];
}

sub foo_aref4 { return [ a => 1, b=> 2 ]; }

# return hash ref
sub foo_href1 {
    # blabla
    return { a => 1, b=> 2 };
}

sub foo_href2 { return { a => 1, b=> 2 }; }

sub foo_href3 {
    my $a = shift @_;
    return { a => $a, b=> 2 };
}

sub foo_href4 { return { a => 1, b=> 2 }; }

# return complex structure
sub foo_struct1 {
    return { a => [1,2,3],
	     b => sub { 1; },
	     c => "bof"
    }
}

sub foo_struct2 { return  { a => [1,2,3], b => sub { 1; }, c => "bof" }
}

sub foo_struct3 {
    return [ 'a',
	     { c => [1,2,3], d => 4,
	       b => "akdjh"},
	     sub { print "foo" }
	];
}

sub foo_struct4 { return  { a => [1,2,3], b => sub { 1; }, c => "bof" }; }

# return anonymous sub

sub foo_sref1 {
    return sub { print "whatever" }
}

sub foo_sref2 { return sub { print "whatever" } }

sub foo_sref3 {
    return sub { print "whatever";
		 my $a = 1;
		 return $a++;
    };
}

sub foo_sref4 { return sub {
    my $a = 1;
    return $a++;
		}; }
