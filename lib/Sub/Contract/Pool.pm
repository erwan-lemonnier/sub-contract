#
#   Sub::Contract::Pool - The pool of contracts
#
#   $Id: Pool.pm,v 1.1 2007-03-30 08:47:49 erwan_lemonnier Exp $
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
#
#

sub list_all_contracts {
    my $self = shift;
    return values %{$self->_contract_index};
}

#---------------------------------------------------------------
#
#
#

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
#
#

sub add_contract {
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

=item C<< $pool-> >>

=back

=head1 SEE ALSO

See 'Sub::Contract'.

=head1 VERSION

$Id: Pool.pm,v 1.1 2007-03-30 08:47:49 erwan_lemonnier Exp $

=head1 AUTHOR

Erwan Lemonnier C<< <erwan@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

This code is distributed under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

This is free code and comes with no warranty. The author declines any personal
responsibility regarding the use of this code or the consequences of its use.

=cut



