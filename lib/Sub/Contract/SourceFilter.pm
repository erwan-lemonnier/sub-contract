#
#   Sub::Contract::SourceFilter - Implement Sub::Contract's source filter
#
#   $Id: SourceFilter.pm,v 1.2 2007-09-16 11:48:06 erwan_lemonnier Exp $
#
#   070915 erwan Started
#

package Sub::Contract::SourceFilter;

use strict;
use warnings;
use Carp qw(croak);
use Data::Dumper;
use Filter::Util::Call;
use Sub::Contract::Pool qw(get_pool);

use accessors ('pkg',                  # package currently source filtered	       
	       'cursub_has_contract',  # the current sub is or not contracted
	       'cursub_name',          # full name of the current sub
	       );

my $pool = Sub::Contract::Pool::get_pool();

# key='pkg::subname'. if key exists, sub has been parsed by source
# filter in package pkg
my $subs_per_pkg = {};

################################################################
#
#
#    Source filter
#
#    - keep track of declared subs in each calling package
#    - add calls to contract validation code to 'sub {' and 'return'
#      for all subs having a contract
#
################################################################

#---------------------------------------------------------------
#
#   new - constructor
#

sub new {
  my ($class,$caller) = @_;

  croak "BUG: no caller provided" if (!defined $caller);

  print "# initializing source filter for caller [$caller]\n" if ($Sub::Contract::DEBUG);

  my $self = bless({},__PACKAGE__);
  $self->pkg($caller);
  $self->cursub_has_contract(0);

  filter_add($self);

  return $self;
}

#---------------------------------------------------------------
#
#   filter - filter each line of the source file
#

sub filter {
  my ($self) = @_;
  my $status = filter_read();
  my $line = $_;

  return $status if ($status < 0);

  print "# filtering ".$self->pkg.", line: $line" if ($Sub::Contract::DEBUG > 1);

  # TODO: keep track of { } to identify the end of a sub?
  # for the moment a sub starts with 'sub word {' and ends at the next 'sub word {'

  # keep track of sub declarations
  if ($line =~ /sub (\w+) {/) {
    my $subname = $self->pkg."::".$1;
    $subname =~ s/::/_/gm;
    $self->cursub_name($subname);
    
    if ($pool->has_contract($subname)) {
      # this sub has a contract
      # replace 'sub {' and the like with 'sub { Sub::Contract::Pool::validate_<package>_<subname>'     
      $self->cursub_has_contract(1);
      $line =~ s/return/return Sub::Contract::Pool::validate_in_$subname/
      
    } else {
      $self->cursub_has_contract(0);
    }
  }

  # replace 'return' with 'return Sub::Contract::Pool::validate_<package>_<subname>' 
  if ($line =~ /\W+return [\$\&\@\%]/ && $self->cursub_has_contract) {
    my $subname = $self->cursub_name;
    $line =~ s/return/return Sub::Contract::Pool::validate_out_$subname/
  }

  $_ = $line;

  print "# into: $_" if ($Sub::Contract::DEBUG > 1);

  return $status;
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
either input arguments or return results.

=head1 API

See 'Sub::Contract'.

=over 4

=item new()

=item add_list_check()

=item add_hash_check()

=item has_list_args()

=item has_hash_args()

=back

=head1 SEE ALSO

See 'Sub::Contract'.

=head1 VERSION

$Id: SourceFilter.pm,v 1.2 2007-09-16 11:48:06 erwan_lemonnier Exp $

=head1 AUTHOR

Erwan Lemonnier C<< <erwan@cpan.org> >>

=head1 LICENSE

See Sub::Contract.

=cut

