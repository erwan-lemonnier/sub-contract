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

# return array ref

# return complex structure

# return anonymous sub

