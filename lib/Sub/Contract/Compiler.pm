#
#   Sub::Contract::Compiler - Compile, enable and disable a contract
#
#   $Id: Compiler.pm,v 1.1 2007-03-30 08:47:49 erwan_lemonnier Exp $
#
#   070228 erwan Wrote API squeleton
#

package Sub::Contract::Compiler;

use strict;
use warnings;
use Carp qw(croak);
use Data::Dumper;
use Hook::WrapSub qw(wrap_subs unwrap_subs);;

#---------------------------------------------------------------
#
#   enable - recompile contract and reenable it
#

sub enable {
    my $self = shift;

    print "Sub::Contract: enabling contract for [".$self->contractor."]\n" if ($Sub::Contract::DEBUG);

    $self->disable if ($self->{is_enabled});

    # compile code to validate pre and post constraints
    my $pre  = _compile('before',
			$self->contractor,
			$self->{in},
			$self->{pre},
			$self->{invariant},
			);

    my $post = _compile('after',
			$self->contractor,
			$self->{out},
			$self->{post},
			$self->{invariant},
			);

    # wrap validation code around contracted sub
    my @args = ($self->contractor);
    unshift @args, $pre if ($pre);
    push @args, $post if ($post);

    wrap_subs(@args);

    # TODO: enable memoization

    $self->{is_enabled} = 1;

    return $self;
}

sub disable {
    my $self = shift;
    if ($self->{is_enabled}) {
	print "disabling contract on ".$self->contractor."\n";

	# restore original sub
	unwrap_subs $self->contractor;

	# TODO: remove memoization
	$self->{is_enabled} = 0;
    }
    return $self;

}

sub is_enabled {
    return $_[0]->{is_enabled};
}

#---------------------------------------------------------------
#
#   _compile - generate the code to validate the contract before
#              or after a call to the contractor function
#

# TODO: split into _compile_code and _generate_code

# croak from contract code, with proper stack level
sub _croak {
    my $msg = shift;
    local $Carp::CarpLevel = 3;
    croak "$msg";
}

# run a condition, with proper stack level if croak
sub _run {
    my ($func,@args) = @_;
    local $Carp::CarpLevel = 4;
    my $res = $func->(@args);
    local $Carp::CarpLevel = 0; # is this needed? isn't local doing its job?
    return $res;
}

sub _compile {
    my ($state,$contractor,$validator,$check_condition,$check_invariant) = @_;
    my (@list_checks,%hash_checks);

    croak "BUG: wrong state" if ($state !~ /^before|after$/);

    # the code validating the pre or post-call part of the contract, as a string
    my $str_code = "";

    # if we are before the function call, keep track of the input arguments
    if ($state eq 'before') {
	$str_code .= q{
	    @Sub::Contract::args = @_;
	    $Sub::Contract::wantarray = $Hook::WrapSub::caller[5];
	    @Sub::Contract::results = ();
	};
    } else {
	$str_code .= q{
	    @Sub::Contract::results = @Hook::WrapSub::result;
	};
    }

    # code validating the contract invariant
    if (defined $check_invariant) {
	$str_code .= sprintf q{
	    if (!_run($check_invariant,@Sub::Contract::args)) {
		_croak "invariant fails %s calling subroutine [%s]";
	    }
	}, $state, $contractor;
    }

    # code validating the contract pre/post condition
    if (defined $check_condition) {
	if ($state eq 'before') {
	    $str_code .= sprintf q{
		if (!_run($check_condition,@_)) {
		    _croak "pre-condition fails before calling subroutine [%s]";
		}
	    }, $contractor;
	} else {
	    # if the contractor is called without context, Hook::WrapSub discards the result
	    # so we can't validate the returned arguments. maybe we should issue a warning?
	    $str_code .= sprintf q{
		if (!_run($check_condition,@Sub::Contract::args)) {
		    _croak "post-condition fails after calling subroutine [%s]";
		}
	    }, $contractor;
	}
    }

    # compile the arguments validation code
    if (defined $validator) {

	@list_checks = @{$validator->list_checks};
	%hash_checks = %{$validator->hash_checks};

	# get args/@_ from right source
	if ($state eq 'before') {
	    $str_code .= q{ my @args = @_; };
	} else {
	    $str_code .= q{ my @args = @Sub::Contract::args; };
	}

	# do we have arguments to validate?
	if ($validator->has_list_args || $validator->has_hash_args) {

	    # add code validating heading arguments passed in list style
	    my $pos = 1;
	    for (my $i=0; $i<scalar(@list_checks); $i++) {
		if (defined $list_checks[$i]) {
		    $str_code .= sprintf q{
			_croak "%s argument %s of [%s] fails its contract constraint"
			    if (!_run($list_checks[%s], $args[0]));
		    },
		    ($state eq 'before')?'input':'return',
		    $pos,
		    $contractor,
		    $i;
		}

		$str_code .= q{
		    shift @args;
		};
		$pos++;
	    }

	    # add code validating trailing arguments passed in hash style
	    if ($validator->has_hash_args) {

		# croak if odd number of elements
		$str_code .= sprintf q{
		    _croak "odd number of hash-style %s arguments in [%s]"
			if (scalar @args %% 2);
		    my %%args = @args;
		},
		($state eq 'before')?'input':'return',
		$contractor;

		# check the value of each key in the argument hash
		while (my ($key,$check) = each %hash_checks) {
		    if (defined $check) {
			$str_code .= sprintf q{
			    _croak "%s argument of [%s] for key \'%s\' fails its contract constraint"
				if (!_run($hash_checks{%s}, $args{%s}));
			},
			($state eq 'before')?'input':'return',
			$contractor,
			$key,
			$key,
			$key;
		    }

		    $str_code .= sprintf q{
			delete $args{%s};
		    }, $key;
		}
	    }
	}

	# there should be no arguments left
	if ($validator->has_hash_args) {
	    $str_code .= sprintf q{
		_croak "function [%s] got too many arguments"
		    if (%%args);
	    }, $contractor;
	} else {
	    $str_code .= sprintf q{
		_croak "function [%s] got too many arguments"
		    if (@args);
	    }, $contractor;
	}
    }



    # croak should look like coming from the real caller package, skip some stack frames!


# TODO: skip compiling after part if not needed

   return undef if ($str_code eq "");

    $str_code = sprintf q{
	$cref = sub {
	    my $res;
	    use Carp;
	    %s
	    }
    }, $str_code;

    if ($Sub::Contract::DEBUG) {
	print "Sub::Contract: wrapping this code $state [$contractor]:\n";
	print "-------------------------------------------------------\n";
	$str_code =~ s/^([\s\t]+)//gm;
	print $str_code;
	print "\n-------------------------------------------------------\n";
    }

    my $cref;
    eval $str_code;

    return $cref;
}

1;

__END__

=head1 NAME

Sub::Contract::Compiler - Compile, enable and disable a contract

=head1 SYNOPSIS

See 'Sub::Contract'.

=head1 DESCRIPTION

Subroutine contracts defined with Sub::Contract must be compiled
and enabled in order to start applying onto the contractor. A
contractor can even be disabled later on, or recompiled after
changes. Those methods are implemented in Sub::Contract::Compiler.

=head1 API

See 'Sub::Contract'.

=head1 SEE ALSO

See 'Sub::Contract'.

=head1 VERSION

$Id: Compiler.pm,v 1.1 2007-03-30 08:47:49 erwan_lemonnier Exp $

=head1 AUTHOR

Erwan Lemonnier C<< <erwan@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

This code is distributed under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

This is free code and comes with no warranty. The author declines any personal
responsibility regarding the use of this code or the consequences of its use.

=cut

