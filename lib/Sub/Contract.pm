#-------------------------------------------------------------------
#
#   Sub::Contract - Pseudo contract programming, and more
#
#   $Id: Contract.pm,v 1.1 2007-03-30 08:47:48 erwan_lemonnier Exp $
#
#   070228 erwan Wrote API squeleton
#

# TODO: different post conditions for undefined/scalar/array context?
# TODO: a way to access the return value of the contractor?

package Sub::Contract;

use strict;
use warnings;
use Carp qw(croak);
use Data::Dumper;
use Symbol;
use Sub::Contract::ArgValidator;
use Sub::Contract::Pool;
use Sub::Contract::Cache;

# Add compiling and memoizing abilities through multiple inheritance, to keep code separate
use base qw(Exporter Sub::Contract::Compiler Sub::Contract::Memoizer);

our @EXPORT = qw();
our @EXPORT_OK = qw(contract results);

our $VERSION = '0.01';

our $DEBUG = 1;

my $pool = Sub::Contract::Pool::get_contract_pool();

# the argument list passed to the contractor
local @Sub::Contract::args;
local $Sub::Contract::wantarray;
local @Sub::Contract::results;

#---------------------------------------------------------------
#
#   results - return @Sub::Contract::result
#

sub results {
    return @Sub::Contract::results;
}

#---------------------------------------------------------------
#
#   contract - the class api part
#

sub contract {
    croak "contract() expects only one argument, a subroutine name" if (scalar @_ != 1 || !defined $_[0]);
    my $caller = caller;
    return new Sub::Contract($_[0], caller => $caller);
}

################################################################
#
#
#   Object API
#
#
################################################################

#---------------------------------------------------------------
#
#   new - instantiate a new subroutine contract
#

sub new {
    my ($class,$contractor,%args) = @_;
    $class = ref $class || $class;
    my $caller = delete $args{caller} || caller();

    croak "new() expects a subroutine name as first argument" if (!defined $contractor);
    croak "new() got unknown arguments: ".Dumper(%args) if (keys %args != 0);

    if ($contractor !~ /::/) {
	$contractor = qualify($contractor,$caller);
    }

    # TODO: die if contractor does not exists? or let the compiler do that?

    my $self = bless({}, $class);
    $self->{is_enabled}  = 0;           # 1 if contract is enabled
    $self->{is_memoized} = 0;           # TODO: needed?
    $self->{contractor}  = $contractor; # The fully qualified name of the contracted subroutine

    $self->reset;

    # add self to the contract pool (if not already in)
    croak "trying to contract function [$contractor] twice"
	if ($pool->has_contract($contractor));

    $pool->add_contract($self);

    return $self;
}

#---------------------------------------------------------------
#
#   reset - reset all constraints in a contract
#

sub reset {
    my $self = shift;
    $self->{in}          = undef;        # An array of coderefs checking respective input arguments
    $self->{out}         = undef;        # An array of coderefs checking respective return arguments
    $self->{pre}         = undef;        # Coderef checking pre conditions
    $self->{post}        = undef;        # Coderef checking post conditions
    $self->{invariant}   = undef;        # Coderef checking an invariant condition
    return $self;
}

#---------------------------------------------------------------
#
#   in, out - declare conditions for each of the subroutine's in- and out-arguments
#

sub _set_in_out {
    my ($type,$self,@checks) = @_;
    local $Carp::CarpLevel = 2;
    my $validator = new Sub::Contract::ArgValidator($type);

    my $pos = 0;

    # check arguments passed in list-style
    while (@checks) {
	my $check = shift @checks;

	if (!defined $check || ref $check eq 'CODE') {
	    # ok
	    $validator->add_list_check($check);
	} elsif (ref $check eq '') {
	    # this is a hash key. we expect hash syntax from there on
	    unshift @checks, $check;
	    last;
	} else {
	    croak "invalid contract definition: argument at position $pos in $type() should be undef or a coderef or a string";
	}
	$pos++;
    }

    # @checks should be either empty or describe hash checks (sequence of string => coderef)
    if (scalar @checks % 2) {
	croak "invalid contract definition: odd number of arguments from position $pos in $type(), can't ".
	    "constrain hash-style passed arguments";
    }

    # check arguments passed in hash-style
    my %known_keys;
    while (@checks) {
	my $key = shift @checks;
	my $check = shift @checks;

	if (defined $key && ref $key eq '') {
	    # is this key defined more than once?
	    if (exists $known_keys{$key}) {
		croak "invalid contract definition: constraining argument \'$key\' twice in $type()";
	    }
	    $known_keys{$key} = 1;

	    # ok with key. verify $check
	    if (!defined $check || ref $check eq 'CODE') {
		# ok
		$validator->add_hash_check($key,$check);
	    } else {
		croak "invalid contract definition: check for \'$key\' should be undef or a coderef in $type()";
	    }
	} else {
	    croak "invalid contract definition: argument at position $pos should be a string in $type()";
	}
	$pos += 2;
    }

    # everything ok!
    $self->{$type} = $validator;
    return $self;
}

sub in   { return _set_in_out('in',@_); }
sub out  { return _set_in_out('out',@_); }

#---------------------------------------------------------------
#
#   pre, post - declare pre and post conditions on subroutine
#

sub _set_pre_post {
    my ($type,$self,$subref) = @_;
    local $Carp::CarpLevel = 2;

    croak "the method $type() expects exactly one argument"
	if (scalar @_ != 3);
    croak "the method $type() expects a code reference as argument"
	if (defined $subref && ref $subref ne 'CODE');

    $self->{$type} = $subref;

    return $self;
}

sub pre  { return _set_pre_post('pre',@_); }
sub post { return _set_pre_post('post',@_); }

#---------------------------------------------------------------
#
#   invariant - adds an invariant condition
#

sub invariant {
    my ($self,$subref) = @_;

    croak "the method invariant() expects exactly one argument"
	if (scalar @_ != 2);
    croak "the method invariant() expects a code reference as argument"
	if (defined $subref && ref $subref ne 'CODE');

    $self->{invariant} = $subref;

    return $self;
}

#---------------------------------------------------------------
#
#   contractor - returns the contractor subroutine's fully qualified name
#

sub contractor {
    return $_[0]->{contractor};
}


# contract('my_func')
#     ->invariant( sub { die "blah" if (ref $_[0] ne 'blob'); } )
#     ->in(prsid => \&check1,
#          fndid => \&check2,
#     )->out(\&is_boolean)
#     ->memoize( max => 1000 );
#
# or
#     ->cache( size => 1000 );
#
# sub my_func {}
#
# my $pool = Sub::Contract::Pool::get_pool;
# $pool->enable_all_contracts;


1;

__END__

=head1 NAME

Sub::Contract - Pragmatic contract programming for Perl

=head1 SYNOPSIS

To contract a function 'divid' that accepts a hash of 2 integer values
and returns a list of the dividend and the modulo of their division:

    contract('divid')
        ->in(a => sub { defined $_ && $_ =~ /^\d+$/},
             b => sub { defined $_ && $_ =~ /^\d+$/},
            )
        ->out(sub { defined $_ && $_ =~ /^\d+$/},
              sub { defined $_ && $_ =~ /^\d+$/},
             )
        ->enable;

    sub divid {
	my %args = @_;
	return ( int($args{a} / $args{b}), $args{a} % $args{b} );
    }

Or, if you have a function C<is_integer>:

    contract('divid')
        ->in(a => \&is_integer,
             b => \&is_integer,
            )
        ->out(\&is_integer, \&is_integer);
        ->enable;

If C<divid> was a method of an instance of 'Maths::Integer':

    contract('divid')
        ->in(sub { defined $_ && ref $_ eq 'Maths::Integer' },
             a => \&is_integer,
             b => \&is_integer,
            )
        ->out(\&is_integer, \&is_integer);
        ->enable;

Or if you don't want to do any check on the object:

    contract('divid')
         ->in(undef,
              a => \&is_integer,
              b => \&is_integer,
             )
        ->out(\&is_integer, \&is_integer);
        ->enable;

You can also declare invariants, pre- and post-conditions as in
common contract programming implementations:

    contract('foo')
         ->pre( \&validate_state_before )
         ->post( \&validate_state_after )
         ->invariant( \&validate_state )
         ->enable;

You may memoize a function's results from its contract:

    contract('foo')->memoize->enable;

You may list contracts during runtime, modify them and recompile
them dynamically, or just turn them off. See 'Sub::Contract::Pool'
for details.

=head1 DESCRIPTION

Sub::Contract offers a pragmatic way to implement parts of the programming
by contract paradigm in Perl.

Sub::Contract doesn't aim at implementing all the properties of contract
programming, but focuses on some that have proven very handy in practice,
and tries to do it in a syntaxically simple way.

With Sub::Contract you can specify a contract per subroutine (or method).
A contract is a set of constraints on the subroutine's input arguments,
returned values, or on a state before and after being called. If one
of these conditions gets broken at runtime, the contract fails and a
runtime error (die or croak) occurs.

Contracts generated by Sub::Contract are objects. Any contract can
be disabled, modified, recompiled and re-enabled at runtime. All
new contracts are automatically added to a contract pool (see Sub::Contract::Pool).
This pool can be searched at runtime for contracts matching some conditions.

The contract definition API is designed pragmatically. Experience shows
that contracts in Perl are mostly used to enforce some form of
argument type validation, hence compensating for Perl's lack of strong
typing. In some cases, one may want to enable contracts during development,
but disable them in production to meet speed requirements (though this is
not encouraged). One may also find it handy to turn on or off memoizing for a
subroutine from the contract definition.

Those pragmatic considerations have shaped the contract API.

=head1 DISCUSSION

=head1 Contracts as objects

Sub::Contract differs from traditional contract programming
frameworks in that it implements contracts as objects that
can be dynamically altered during runtime. The idea of altering
a contract during runtime may seem to conflict with the definition
of a contract, but it makes sense when considering that Perl being
a dynamix language, all code can change behaviour during runtime.

----Besides, the availability of all contracts via the contract pool
at runtime gives a powerfull tool for

=head1 Error messages

When a call to a contractor function breaks the contract, call fails contract fails

=head1 Issues with contract programming

TODO: contract inheritance? should child classes inherit from parent classes's contracts?
TODO: relevant error messages

=head2 Sub::Contract VERSUS Class::Contract

TODO: with Class::Contract you can only define contracts on object methods. No memoization.

=head2 Sub::Contract VERSUS Class::Agreement

TODO: basically the same functionality, but one has a procedural api, the later a oo api + no memoization
no pre/post conditions on variables, only on subs. better respect of calling context.


TODO: more description
TODO: how to enable contracts -> enable on each contract, or via the pool

TODO: validation code should not change @_, else weird bugs...



=head1 Object API

=over 4

=item C<< my $contract = new Sub::Contract($qualified_name) >>

Return an empty contract for the function named C<$qualified_name>.

If C<$qualified_name> is a function name without the package it is in,
the function is assumed to be in the caller package.

A given function can be contracted only once. If you want to modify a
function's contract after having enabled the contract, you can't just
call C<Sub::Contract->new> again. Instead you must retrieve the contract
object for this function, modify it and enable it anew. Retrieving the
function's contract object can be done by querying the contract pool
(See 'Sub::Contract::Pool').

=item C<< my $contract = new Contract::Sub($name, caller => $package) >>

Same as above, excepts that the contractor is the function C<$name>
located in package C<$package>.

=item C<< $contract->invariant($coderef) >>

Execute C<$coderef> both before and after calling the contractor.
C<$coderef> gets in arguments the arguments passed to the contractor.
C<$coderef> should return 1 if the condition passes and 0 if it fails.
C<$coderef> may croak, in which case the error will look as if caused
by the calling code. Do not C<die> from C<$coderef>, C<croak> instead.

=item C<< $contract->pre($coderef) >>

Same as C<invariant> but executes C<$coderef> only before calling the
contractor.

=item C<< $contract->post($coderef) >>

Same as C<pre> but executes C<$coderef> when returning from calling
the contractor.

=item C<< $contract->in(@checks) >>

Validate each input argument of the contractor one by one.

C<@checks> declares which validation functions should be called
for each input argument. The syntax of C<@checks> supports arguments
passed in array-style or hash-style or a mix of both.


TODO: syntax for @checks

=item C<< $contract->out(@checks) >>

Same as C<in> but for validating return arguments one by one.

TODO: context dependency


=item C<< $contract->reset >>

Remove all previsouly defined constraints from this contract. Does not
affect the contract validation code as long as you don't call C<enable>
after C<reset>. C<reset> is usefull if you want to redefine a contract
from scratch during runtime.

=item C<< $contract->enable >>

Compile and enable a contract. If the contract is already enabled, it is
first disabled.

Enabling the contract consists in dynamically generating
some code that validates the contract before and after calls to the
contractor and wrapping this code around the contractor.

=item C<< $contract->disable >>

Disable the contract: remove the wrapper code generated and added by C<enable>
from around the contractor.

=item C<< $contract->is_enabled >>

Returns true if this contract is currently enabled

=item C<< $contract-> >>

=item C<< $contract-> >>


=back

=head1 Class API

=over 4

=item C<< contract($qualified_name) >>

Same as C<new Sub::Contract($qualified_name)>.
Must be explicitly imported:

    use Sub::Contract qw(contract);

=item C<< returns() >>

Returns the result returned by the last call to the contractor
function. Usefull when coding invariant or post condition checks.

Note that C<returns> is context dependant: if the contractor was
called in scalar context, C<returns> will return the result as it
would be in scalar context, and C<returns> will return an empty
list if the contractor was called in no context. You might therefore
want to query C<< Sub::Contract::wantarray >>.

Must be explicitly imported:

    use Sub::Contract qw(returns);

=back

=head1 Class variables

The value of the following variables is set by Sub::Contract before
executing any contract validation code. They are designed to be used
inside the contract validation code.

=over 4

=item C<< $Sub::Contract::wantarray >>

1 if the contractor is called in array context, 0 if it is called
in scalar context, and undef if called in no context. This affects
the value of C<< Sub::Contract::results >>.

=item C<< @Sub::Contract::args >>

The input arguments that the contractor is being called with.

=item C<< @Sub::Contract::results >>

The result(s) returned by the contractor, as seen by its caller.
Can also be accessed with the exported function 'returns'.

=back

The following example code uses those variables to validate
that a function C<foo> returns C<< 'array' >> in array context
and C<< 'scalar' >> in scalar context:

    use Sub::Contract qw(contract results);

    contract('foo')
        ->post(
            sub {
                 my @results = returns;

                 if ($Sub::Contract::wantarray == 1) {
                     return defined $results[0] && $results[0] eq "array";
                 } elsif ($Sub::Contract::wantarray == 0) {
                     return defined $results[0] && $results[0] eq "scalar";
                 } else {
                    return 1;
		 }
	     }
        )->enable;

=head1 SEE ALSO

See 'Sub::Contract'.

=head1 VERSION

$Id: Contract.pm,v 1.1 2007-03-30 08:47:48 erwan_lemonnier Exp $

=head1 AUTHOR

Erwan Lemonnier C<< <erwan@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

This code is distributed under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

This is free code and comes with no warranty. The author declines any personal
responsibility regarding the use of this code or the consequences of its use.

=cut



