#
#   Sub::Contract::Pool - The pool of contracts
#
#   $Id: Pool.pm,v 1.2 2007-04-27 12:46:29 erwan_lemonnier Exp $
#
#   070228 erwan Wrote API squeleton
#

package Sub::Contract::Pool;

use strict;
use warnings;

use Carp qw(croak);

use accessors qw( _contract_index
		);

use base qw(Exporter);

our @EXPORT = ();
our @EXPORT_OK = ('get_contract_pool');

#---------------------------------------------------------------
#
#   A singleton pattern with lazy initialization and embedded constructor
#

my $pool;

sub get_contract_pool {
    if (!defined $pool) {
	$pool = bless({},__PACKAGE__);
	$pool->_contract_index({});
    }
    return $pool;
}

# make sure no one calls the constructor
sub new {
    croak "use get_contract_pool() instead of new()";
}

#---------------------------------------------------------------
#
#   list_all_contracts - return all contracts registered in the pool
#

sub list_all_contracts {
    my $self = shift;
    return values %{$self->_contract_index};
}

#---------------------------------------------------------------
#
#   has_contract - 
#

# TODO: should it be removed? to use find_contract instead?

sub has_contract {
    my ($self, $contractor) = @_;

    croak "method has_contract() expects only 1 argument"
	if (scalar @_ != 2);
    croak "method has_contract() expects a fully qualified function name as argument"
	if (!defined $contractor || ref $contractor ne '' || $contractor !~ /::/);

    my $index = $self->_contract_index;
    return exists $index->{$contractor};
}

#---------------------------------------------------------------
#
#   _add_contract
#

sub _add_contract {
    my ($self, $contract) = @_;

    croak "method add_contract() expects only 1 argument"
	if (scalar @_ != 2);
    croak "method add_contract() expects an instance of Sub::contract as argument"
	if (!defined $contract || ref $contract ne 'Sub::Contract');

    my $index = $self->_contract_index;
    my $contractor = $contract->contractor;

    croak "trying to contract function [$contractor] twice"
	if ($self->has_contract($contractor));

    $index->{$contractor} = $contract;

    return $self;
}

################################################################
#
#
#   Operations on contracts during runtime
#
#
################################################################

sub enable_all_contracts {}
sub disable_all_contracts {}


#sub list_contracts_in_package {}

sub find_contract {
    my $self = shift;
    # accept package => $regexp
    # accept function => $regexp
    # accept fully_qualified_name => $regexp

    # TODO: search contracts matching func/pkg name. name can be a regexp
    # TODO: return a list of Sub::Contract objects
}


1;

__END__

=head1 NAME

Sub::Contract::Pool - A pool of all subroutine contracts

=head1 SYNOPSIS

    use Sub::Contract::Pool qw(get_contract_pool);

    my $pool = get_contract_pool();

TODO

=head1 DESCRIPTION

All subroutine contracts defined via creating instances of
Sub::Contract or Sub::Contract::Memoizer are automatically
added to a pool of contracts.

You can query this pool to retrieve contracts defined for
specific parts of your code, and modify, recompile, enable
and disable contracts selectively at runtime.

Sub::Contract::Pool is a singleton pattern, giving you
access to a unique contract pool created at compile time
by Sub::Contract.

=head1 API

=over 4

=item C<< my $pool = get_contract_pool() >>;

Return the contract pool.

=item C<< new() >>

Pool constructor, for internal use only.
DO NOT USE NEW, always use C<< get_contract_pool() >>.

=item C<< $pool->list_all_contracts >>

Return all contracts registered in the pool.

=item C<< $pool->has_contract($fully_qualified_name) >>

Return true if the subroutine identified by C<$fully_qualified_name>
has a contract.

=item C<< $pool->enable_all_contracts >>

Enable all the contracts registered in the pool.

=item C<< $pool->disable_all_contracts >>

Disable all the contracts registered in the pool.

=item C<< $pool->find_contract() >>

TODO

=back

=head1 SEE ALSO

See 'Sub::Contract'.

=head1 VERSION

$Id: Pool.pm,v 1.2 2007-04-27 12:46:29 erwan_lemonnier Exp $

=head1 AUTHOR

Erwan Lemonnier C<< <erwan@cpan.org> >>

=head1 LICENSE

See Sub::Contract.

=cut



