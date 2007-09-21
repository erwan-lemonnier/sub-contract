#
#   Sub::Contract::SourceFilter - Implement Sub::Contract's source filter
#
#   $Id: SourceFilter.pm,v 1.4 2007-09-21 14:14:59 erwan_lemonnier Exp $
#
#   070915 erwan Started
#

package Sub::Contract::SourceFilter;

use strict;
use warnings;
use Carp qw(croak confess);
use Data::Dumper;
use PPI;
use PPI::Find;
use PPI::Token::Word;
use Filter::Util::Call;
use Sub::Contract::Pool qw(get_pool);
use Sub::Contract::Debug qw(debug);

my $pool = Sub::Contract::Pool::get_pool();

# NOTE: we had 2 alternative designs to choose from:
#
# 1. wrap ALL subroutines in ALL packages calling 'use Sub::Contract'
#    with calls to contract validation code
# or
# 2. keep track of calls to the 'contract' function in each parsed
#    package and wrap only the contracted subroutines in that
#    package with validation code
#
# (1) has some advantages compared to (2):
# - we don't have to declare contracts in the same file in which
#   the contracted subs are declared. contracts and subs declarations
#   can be separated.
# - contracts can be made truly dynamic: contract declarations can be
#   declared and compiled at runtime, even for subroutine that had no
#   contract in the source file.
#
# (1) has one disadvantage though: we loose a bit of efficiency since
# ALL subroutines receive some new code...
#
# In the current implementation, (1) won: all subroutines are patched...

#---------------------------------------------------------------
#
#   new - constructor
#

sub new {
  debug(1,"initializing source filter for caller [".caller(1)."]");

  my $self = bless({},__PACKAGE__);
  filter_add($self);

  return $self;
}

#---------------------------------------------------------------
#
#   filter - filter each line of the source file
#

sub filter {
  my ($self) = @_;
  my $status;

  do {
      $status = filter_read();
  } until ($status == 0);

  # TODO: croak here, or let Filter::Util::Call croak for us?
  croak "an error occured while filtering ".$self->pkg.": $!"
      if ($status < 0);

  return 0 if (length($_) == 0);

  # $_ now contains the whole remaining source.
  # parse it with PPI
  my $doc = PPI::Document->new(\$_) ||
      croak "failed to parse ".$self->pkg." with PPI: ".PPI::Document::errstr;

  # do not look for subs recursively: skip any anonymous sub
  # declared within a sub.
  my $topsubs = $doc->find( sub {
      ref $_[1] ne '' && $_[1]->parent == $_[0] && $_[1]->isa('PPI::Statement::Sub');
  });

  if (ref $topsubs eq '') {
      # empty body
      return 1;
  }

  # foreach sub declaration in the source file
  foreach my $esub (@$topsubs) {

      #
      # step 1: identify name of subroutine
      #

      # name should be the next word after 'sub'
      my @words = @{$esub->find('PPI::Token::Word')};

      confess "BUG: expected 'sub'" if ($words[0]->content ne 'sub');

      my $name = $words[1]->content;

      #
      # step 2: append and prepend validation code to subroutine code
      #

      # add an extra ';' to $code_post in case last code line in sub lacks one
      my $code_pre    = PPI::Token::Word->new("Sub::Contract::Pool::_validate_".$name."_in(\@_);");
      my $code_post   = PPI::Token::Word->new("; Sub::Contract::Pool::_validate_".$name."_out(\$_);");

      # find the begining of the sub block ('{' sign)
      my @blocks = @{ $esub->find( sub {
	  ref $_[1] ne '' && $_[1]->parent == $_[0] && $_[1]->isa('PPI::Structure::Block');
      }) };
      croak "found no or more than 1 sub block" if (scalar @blocks != 1);

      my $subdef = $blocks[0];

      # add code at the begining and the end of the sub
      my @children = $subdef->children;

      if (scalar @children == 0) {
	  # empty sub declaration: 'sub {}'
	  $blocks[0]->add_element($code_pre);
	  $blocks[0]->add_element($code_post);
      } else {
	  $children[0]->insert_before($code_pre);
	  $children[-1]->insert_before($code_post);
      }

      #
      # step 3: alter 'return' statements
      #

      foreach my $word (@{ $subdef->find('PPI::Token::Word') }) {
	  if ($word->content eq 'return') {

	      # this word is 'return'
	      my $ret_start = $word;

	      do {
		  $word = $word->next_sibling;
	      } until (ref $word eq '' || ($word->isa('PPI::Token::Structure') && $word->content eq ';') );

	      my $ret_end = $word;

	      if (ref $ret_end eq "") {
		  # there was no ';' after return...
		  $ret_start->set_content("return Sub::Contract::Pool::_validate_".$name."_out()");
	      } else {
		  # this word is ';' after the variables following 'return'
		  $ret_start->set_content("return Sub::Contract::Pool::_validate_".$name."_out(");
		  $ret_end->set_content(");");
	      }
	  }
      }
  }

  # serialize back the modified source tree
  $_ = $doc->serialize;

  debug(3,"filtered source into:\n[$_]");

  return 1;
}

1;

__END__

=head1 NAME

Sub::Contract::SourceFilter - Add contract validation code to subroutines

=head1 SYNOPSIS

Turn Sub::Contract into a source filter:

    sub import {
        new Sub::Contract::SourceFilter;
    }

=head1 DESCRIPTION

Sub::Contract::SourceFilter implement the source filter part of Sub::Contract.

It extends Filter::Util::Call and parses the stream of source code with PPI.
It searches through the PDOM tree representation provided by PPI and lists
all contract declarations, then modifies the tree to append and prepend
validation code to each contracted subroutine. The tree is then serialized
back into perl code which is passed to the compiler.

=head1 API

=over 4

=item new() Constructor. Call C<filter_add> on self.

=item filter() Method required by C<Filter::Util::Call>. Does all the magic.

=back

=head1 SEE ALSO

See 'Sub::Contract', 'Filter::Util::Call', 'perlfilter'.

=head1 VERSION

$Id: SourceFilter.pm,v 1.4 2007-09-21 14:14:59 erwan_lemonnier Exp $

=head1 AUTHOR

Erwan Lemonnier C<< <erwan@cpan.org> >>

=head1 LICENSE

See Sub::Contract.

=cut

