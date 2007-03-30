#
#   Sub::Contract::ArgValidator - Validate input/result arguments
#
#   $Id: ArgValidator.pm,v 1.1 2007-03-30 08:47:49 erwan_lemonnier Exp $
#
#   070228 erwan Wrote API squeleton
#

package Sub::Contract::ArgValidator;

use strict;
use warnings;
use Carp qw(croak);
use Data::Dumper;

use accessors ('type',         # 'in' or 'out'
	       'list_checks',  # an anonymous array of checks on list-style passed arguments
	       'hash_checks',  # an anonymous hash of checks on hash-style passed arguments
	       );

#---------------------------------------------------------------
#
#   new - constructor
#

sub new {
    my($class,$type) = @_;
    $class = ref $class || $class;

    croak "BUG: type must be in or out" if ($type !~ /^(in|out)$/);

    my $self = bless({},$class);
    $self->type($type);
    $self->list_checks([]);
    $self->hash_checks({});
}

sub add_list_check {
    my ($self,$check) = @_;
    push @{$self->list_checks}, $check;
}

sub add_hash_check {
    my ($self,$key,$check) = @_;
    $self->hash_checks->{$key} = $check;
}

sub has_list_args {
    return scalar @{$_[0]->list_checks};
}

sub has_hash_args {
    return scalar keys %{$_[0]->hash_checks};
}


1;

__END__

=head1 NAME

Sub::Contract::ArgValidator - Validate input/result arguments

=head1 SYNOPSIS

See 'Sub::Contract'.

=head1 DESCRIPTION

Subroutine contracts defined with Sub::Contract have a specific
syntax to define fine grained constraints on the input and result
arguments of a subroutine, as defined with the methods in() and out().

An instance of Sub::Contract::Arg holds those constraints for
either input or return arguments.

=head1 API

See 'Sub::Contract'.

=head1 SEE ALSO

See 'Sub::Contract'.

=head1 VERSION

$Id: ArgValidator.pm,v 1.1 2007-03-30 08:47:49 erwan_lemonnier Exp $

=head1 AUTHOR

Erwan Lemonnier C<< <erwan@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

This code is distributed under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

This is free code and comes with no warranty. The author declines any personal
responsibility regarding the use of this code or the consequences of its use.

=cut

