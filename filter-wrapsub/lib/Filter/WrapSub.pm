#-------------------------------------------------------------------
#
#   Filter::WrapSub - Wrap a sub with code at compile time
#
#   $Id: WrapSub.pm,v 1.2 2007-09-24 18:02:24 erwan_lemonnier Exp $
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

=head1 SYNOPSIS: INSERTING CODE

Let's assume you have written a small package containing one function:

    package Small::Package;

    sub incr {
        my $a = shift;
        $a = $a + 1;
        return $a;
    }

Now, suppose that for some reason you want to add some code
at the begining and at the end of the subroutine body, before
compile time, in order for it to look like this:

    sub incr { print "start!\n";
        my $a = shift;
        $a = $a + 1;
        print "end!\n"; return $a; 
    }

(note: If we inserted new lines, the line numbers shown in runtime error
messages would not match the source code anymore. We therefore want the
new code to be appended to existing lines)

For that to happen, just create the following source filter:

    package My::SourceFilter

    use Filter::WrapSub;

    sub import {
        new Filter::WrapSub(
            insert_at_start  => 'print "start!\n"',
            replace_return   => 'print "end!\n"; return $a'
        );
    }

And edit your package to use your source filter:

    package Small::Package;

    use My::SourceFilter;

    sub incr {
        my $a = shift;
        $a = $a + 1;
        return $a;
    }

Voila! Next time you compile Small::Package, My::SourceFilter will
tell Filter::WrapSub to modify the source code before compile time,
and add the print lines at the beginning and end of C<incr>'s body.

=head1 SYNOPSIS: INSERTING FUNCTION CALLS

Now, suppose you want to modify incr to look like this:

    sub incr { check_is_integer(@_);
        my $a = shift;
        $a = $a + 1;
        return check_return_value($a);
    }

In other words, you want to intercept the input and return arguments
of C<incr> and do stuff with them, but via a source filter, at compile
time.

Do like above, except that your filter should look like:

    package My::SourceFilter

    use Filter::WrapSub;

    sub import {
        new Filter::WrapSub(
            insert_at_start => 'check_is_integer(@_)',
            replace_return  => 'return check_return_value($a)'
        );
    }

The bad thing with those two solutions is that you need to know the name
of the variable C<$a>. Furthermore, the source filter My::SourceFilter
would insert code within the body of every single subroutine
declared within the package Small::Package. Not so good. Read further:

=head1 SYNOPSIS: GENERATING THE INSERTED CODE

In the above example, 
You won't go far with that kind of default behavior. Most of the
time, you will want to insert code into the body of only a few
specific subroutines, or to generate different inserted code for
different subroutines, or generate different inserted code
based on whatever properties you may wish to look for within
the whole source of Small::Package.

Filter::WrapSub offers a mechanism to do just that. Call C<new Filter::WrapSub>
with subroutine references instead of strings:

    package My::SourceFilter

    use Filter::WrapSub;

    sub import {
        new Filter::WrapSub(
            exec_begin => &generate_pre_code,
            exec_end   => &generate_post_code
        );
    }

    sub generate_pre_code {
        my ($sub_name, $sub_pdom, $pkg_pdom) = @_;
	return "print \"entering $subname\n\";";
    }

    sub generate_post_code {
        my ($sub_name, $sub_pdom, $pkg_pdom) = @_;
	return "print \"leaving $subname\n\";";
    }

Or to insert function calls:

    package My::SourceFilter

    use Filter::WrapSub;

    sub import {
        new Filter::WrapSub(
            call_begin => &generate_pre_code,
            call_end   => &generate_post_code
        );
    }

    sub generate_pre_code {
        my ($sub_name, $sub_pdom, $pkg_pdom) = @_;
	return "print \"entering $subname\n\";";
    }


You may want to add a bit more of logic 


=head1 SYNOPSIS: WHEN THERE IS NO RETURN...

A subroutine body may look like:

    use My::SourceFilter;

    # some code...

    sub foo {
        my $a = shift;
        if ($a = 1) {
            print "bingo!\n";
            return 1;
        }
    }

C<foo> does not always end with a call to C<return>. Let's
assume that despite this limitation you want to always call a function
named C<debug> with the return value of C<foo> when leaving foo.
You can do that by creating a new Filter::WrapSub and specifying
C<replace_return> and C<insert_at_end>:

    package My::SourceFilter

    use Filter::WrapSub;

    sub import {
        new Filter::WrapSub(
            replace_return  => sub {
                my ($sub_name, $return_args, $sub_pdom, $doc_pdom) = @_;
                return "debug($return_args) && return $return_args";
            },
            insert_at_end   => 'debug(undef)'
        );
    }

After being source filtered, C<foo> will look like:

    sub foo { 
        my $a = shift;
        if ($a = 1) {
            print "bingo!\n";
            return 1;
        }
    }




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

=head1 WHY?

TODO: problem with Hook::WrapSub and the like: slow, confusing function stack (anonymous) and harder to follow in debugger

=head1 SEE ALSO

See Filter::Util::Call.

=head1 BUGS

See PPI.

=head1 VERSION

$Id: WrapSub.pm,v 1.2 2007-09-24 18:02:24 erwan_lemonnier Exp $

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



