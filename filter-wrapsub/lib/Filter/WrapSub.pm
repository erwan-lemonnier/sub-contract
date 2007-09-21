#-------------------------------------------------------------------
#
#   Filter::WrapSub - Wrap a sub with code at compile time
#
#   $Id: WrapSub.pm,v 1.1 2007-09-21 14:14:04 erwan_lemonnier Exp $
#
#   070921 erwan Laying foundations
#

package Filter::WrapSub;

use strict;
use warnings;
use Carp qw(croak);
use Data::Dumper;
use PPI;
use Filter::Util::Call;

our $VERSION = '0.01';

use accessors ('pkg',                  # package currently source filtered
	       'cursub_has_contract',  # the current sub is or not contracted
	       'cursub_name',          # full name of the current sub
	       );

#---------------------------------------------------------------
#
#   new - constructor
#

sub new {
  my ($class,$caller) = @_;

  croak "BUG: no caller provided" if (!defined $caller);

  debug(1,"initializing source filter for caller [$caller]");

  my $self = bless({},__PACKAGE__);
  $self->pkg($caller);
  $self->cursub_has_contract(0);

  filter_add($self);

  return $self;
}


1;

__END__

=head1 NAME

Filter::WrapSub - Wrap a sub with code at compile time

=head1 SYNOPSIS

Suppose you want to write a source filter that adds
a print statement at the begining and the end of every
subroutine in the packages that use it. Your source
filter could look like:

    package My::AddPrint;

    sub import {
	new Sub::Contract::SourceFilter(
            sub_start  => sub { return "print 'entering '".$_[0]."'\n'" },
            sub_end    => sub { return "print 'leaving '".$_[0]."'\n'" },
            sub_return => sub { return "print 'entering '".$_[0]."'\n'" },

    }




Note that you don't need to use Filter::Call::Util since
Filter::WrapSub does it for you.


=head1 DESCRIPTION

Filter::WrapSub lets you easily write a source filter to wrap
a sub with code at compile time. It lets you insert code at the
very begining of each sub body and at the end, as well as beside
every C<return> statement.

If you are familiar with Hook::WrapSub or Hook::LexWrap, Filter::WrapSub
has a similar intent. But where those C<Hook::> modules work by
replacing the wrapped sub with a closure that contains pre- and post-execution
code, Filter::WrapSub adds the code directly in the source before
it is compiled.

To use Filter::WrapSub you are expected to be familiar with source filters.

TODO

=head1 API

=over 4

=item C<< new >>

=back

=head1 SEE ALSO

See Filter::Util::Call.

=head1 BUGS

See PPI.

=head1 VERSION

$Id: WrapSub.pm,v 1.1 2007-09-21 14:14:04 erwan_lemonnier Exp $

=head1 AUTHORS

Erwan Lemonnier C<< <erwan@cpan.org> >>,
as part of the Pluto developer group at the Swedish Premium Pension Authority.

=head1 LICENSE

This code was developed at the Swedish Premium Pension Authority as part of
the Authority's software development activities. This code is distributed
under the same terms as Perl itself. We encourage you to help us improving
this code by sending feedback and bug reports to the author(s).

This code comes with no warranty. The Swedish Premium Pension Authority and the author(s)
decline any responsibility regarding the possible use of this code or any consequence
of its use.

=cut



