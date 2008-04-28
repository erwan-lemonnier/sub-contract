#
#   Sub::Contract::Compiler - Compile, enable and disable a contract
#
#   $Id: Compiler.pm,v 1.7 2008-04-28 15:47:50 erwan_lemonnier Exp $
#

package Sub::Contract::Compiler;

use strict;
use warnings;
use Carp qw(croak confess);
use Data::Dumper;
use Sub::Contract::Debug qw(debug);
use Hook::WrapSub qw(wrap_subs unwrap_subs);

#---------------------------------------------------------------
#
#   enable - recompile contract and reenable it
#

sub enable {
    my $self = shift;

    debug(1,"Sub::Contract: enabling contract for [".$self->contractor."]");

    $self->disable if ($self->{is_enabled});

    # compile code to validate pre and post constraints
    my $cref_pre  = _compile('before',
			     $self->contractor,
			     $self->{in},
			     $self->{pre},
			     $self->{invariant},
			     );

    my $cref_post = _compile('after',
			     $self->contractor,
			     $self->{out},
			     $self->{post},
			     $self->{invariant},
			     );

    # find contractor's code ref
    my $cref = $self->contractor_cref;

    # wrap validation code around contracted sub
    my $contract = sub {
	# TODO: this code is not re-entrant. use local variables for args/wantarray/results. is local enough?


	local @Sub::Contract::args = @_;
	local $Sub::Contract::wantarray = wantarray;
	local @Sub::Contract::results = ();

	if (!defined $Sub::Contract::wantarray) {
	    # void context
	    &$cref_pre() if ($cref_pre);
	    &$cref(@Sub::Contract::args);
	    @Sub::Contract::results = ();
	    &$cref_post(@Sub::Contract::results) if ($cref_post);
	    return ();

	} elsif ($Sub::Contract::wantarray) {
	    # array context
	    &$cref_pre() if ($cref_pre);
	    @Sub::Contract::results = &$cref(@Sub::Contract::args);
	    &$cref_post() if ($cref_post);
	    return @Sub::Contract::results;

	} else {
	    # scalar context
	    &$cref_pre() if ($cref_pre);
	    my $s = &$cref(@Sub::Contract::args);
	    @Sub::Contract::results = ($s);
	    &$cref_post() if ($cref_post);
	    return $s;
	}
    };

    # replace contractor with contract sub
    $^W = 0;
    no strict 'refs';
    no warnings;
    *{ $self->contractor } = $contract;

    $self->{is_enabled} = 1;

    return $self;
}

sub disable {
    my $self = shift;
    if ($self->{is_enabled}) {
	debug(1,"Sub::Contract: disabling contract on [".$self->contractor."]");

	# restore original sub
	$^W = 0;
	no strict 'refs';
	no warnings;
	*{ $self->contractor } = $self->{contractor_cref};

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

# TODO: insert _croak inline in compiled code
# croak from contract code, with proper stack level
sub _croak {
    my $msg = shift;
    local $Carp::CarpLevel = 3;
    croak "$msg";
}

# TODO: insert _run inline in compiled code
# run a condition, with proper stack level if croak
sub _run {
    my ($func,@args) = @_;
    local $Carp::CarpLevel = 4;
    my $res = $func->(@args);
    local $Carp::CarpLevel = 0; # is this needed? isn't local doing its job?
    return $res;
}

# The strategy we use for building the contract validation sub is to
# to (quite horribly) build a string containing the code of the validation sub,
# then compiling this code with eval. We could instead use a closure,
# but that would mean that many things we can test at compile time would
# end up being tested each time the closure is called which would be a
# waste of cpu.

sub _compile {
    my ($state,$contractor,$validator,$check_condition,$check_invariant) = @_;
    my (@list_checks,%hash_checks);

    croak "BUG: wrong state" if ($state !~ /^before|after$/);

    # the code validating the pre or post-call part of the contract, as a string
    my $str_code = "";

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
		if (!_run($check_condition,@Sub::Contract::args)) {
		    _croak "pre-condition fails before calling subroutine [%s]";
		}
	    }, $contractor;
	} else {
	    # if the contractor is called without context, Hook::WrapSub discards the result
	    # so we can't validate the returned arguments. maybe we should issue a warning?
	    $str_code .= sprintf q{
		if (!_run($check_condition,@Sub::Contract::results)) {
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
	    $str_code .= q{ my @args = @Sub::Contract::args; };
	} else {
	    $str_code .= q{ my @args = @Sub::Contract::results; };
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

# TODO: skip compiling after part if not needed

   return undef if ($str_code eq "");

    $str_code = sprintf q{
	$cref = sub {
	    use Carp;
	    %s
	    }
    }, $str_code;

    # remove confusing left indentation
    $str_code =~ s/^\s+//gm;

    debug(2,join("\n",
		 "Sub::Contract: wrapping this code $state [$contractor]:",
		 "-------------------------------------------------------",
		 $str_code,
		 "-------------------------------------------------------"));

    my $cref;
    eval $str_code;

    if (defined $@ and $@ ne "") {
	confess "BUG: failed to compile contract ($@)";
    }

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
changes. Those methods are implemented in Sub::Contract::Compiler
and inherited by Sub::Contract.

=head1 API

See 'Sub::Contract'.

=over 4

=item enable()

See 'Sub::Contract'.

=item disable()

See 'Sub::Contract'.

=item is_enabled()

See 'Sub::Contract'.

=back

=head1 SEE ALSO

See 'Sub::Contract'.

=head1 VERSION

$Id: Compiler.pm,v 1.7 2008-04-28 15:47:50 erwan_lemonnier Exp $

=head1 AUTHOR

Erwan Lemonnier C<< <erwan@cpan.org> >>

=head1 LICENSE

See Sub::Contract.

=cut

