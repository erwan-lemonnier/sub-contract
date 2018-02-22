Module Version: 0.12

# NAME

Sub::Contract - Pragmatic contract programming for Perl

# SYNOPSIS

First of all, you should define a library of pseudo-type constraints. A type constraint is a subroutine that returns true if the argument if of the right type, and returns false or croaks if not. Example:

    use Regexp::Common;

    # test that variable is an integer
    sub is_integer {
        my $i = shift;
        return 0 if (!defined $i);
        return 0 if (ref $i ne "");
        return 0 if ($i !~ /^$RE{num}{int}$/);
        return 1;
    }

    sub is_shortdate      { ... }
    sub is_account_number { ... }
    sub is_amount         { ... }
    # and so on...
    
To contract a function 'surface' that takes a list of 2 integers and returns 1 integer:

    use Sub::Contract qw(contract);

    contract('surface')
        ->in(\&is_integer, \&is_integer)
        ->out(\&is_integer)
        ->enable;

    sub surface {
        # no need to validate arguments anymore!
        # just implement the logic:
        return $_[0] * $_[1];
    }
    
Since the result of 'surface' is a function of its input arguments only, we may want to memoize (cache) it:

    contract('surface')
        ->in(\&is_integer, \&is_integer)
        ->out(\&is_integer)
        ->cache
        ->enable;
        
If 'surface' took a hash of 2 integers instead, with the keys 'height' and 'width':

    use Sub::Contract qw(contract);

    contract('surface')
        ->in(height => \&is_integer, width => \&is_integer)
        ->out(\&is_integer)
        ->enable;

    sub surface {
        my %args = @_;
        return $args{height}* $args{width};
    }
    
Of course, a real life example is more likly to look like:

    use Sub::Contract qw(contract is_a);

    # contract the method 'send_money' from class 'My::Account'
    contract("send_money")
        ->in( is_a('My::Account'),
              to => is_a('My::Account'),
              amount => \&is_integer,
              date => \&is_date )
         ->out( is_a('My::StatusCode') )
         ->enable;

    # and a call to 'send_money' may look like:
    my $account1 = new My::Account("you");
    my $account2 = new My::Account("me");

    $account1->send_money( to => $account2,
                           amount => 1000,
                           date => "2008-06-16" );
                           
To make an argument of return value free of constraint, just set its constraint to undef:

    contract("send_money")
        ->in( undef,            # no need to check self
              to => is_a('My::Account'),
              amount => undef,  # amount may be whatever
              date => \&is_date )
         ->enable;
         
You can also declare invariants, pre- and post-conditions as in usual contract programming implementations:

    contract('foo')
         ->pre( \&validate_state_before )
         ->post( \&validate_state_after )
         ->invariant( \&validate_state )
         ->enable;
         
To turn off all contracts within namespaces matching '^My::Account::.*$'

    use Sub::Contract::Pool qw(get_contract_pool);

    my $pool = get_contract_pool();
    foreach my $contract ($pool->find_contracts_matching("My::Account::.*")) {
        $contract->disable;
    }
    
You may list contracts during runtime, modify them and recompile them dynamically, or just turn them off. See 'Sub::Contract::Pool' for details.

# DESCRIPTION

Sub::Contract offers a pragmatic way to implement parts of the programming by contract paradigm in Perl.

Sub::Contract is not a design-by-contract framework.

Sub::Contract aims at making it very easy to constrain subroutines input arguments and return values in order to emulate strong type checking at runtime.

Perl is a weakly typed language in which variables have a dynamic content at runtime. A feature often wished for in such circumstances is a way to define constraints on a subroutine's arguments and on its return values. A constraint is basically a test that the specific argument has to pass otherwise an error is raised.

For example, a subroutine add() that takes 2 integers and return their sum could have constraints on both input arguments and on the return value stating that they must be defined and be integers or else we croak. That kind of tests is usually writen explicitely within the subroutine's body, hence leading to an overflow of argument validation code. With Sub::Contract you can move this code outside the subroutine body in a relatively simple and elegant way. The code for add() and its contract could look like:

    contract('add')
        ->in(\&is_integer,\&is_integer)
        ->out(\&is_integer)
        ->enable;

    sub add { return $_[0]+$_[1] }
Sub::Contract doesn't aim at implementing all the properties of contract programming, but focuses on some that have proven handy in practice and tries to do it with a simple syntax.

Perl also support calling contexts which can lead to tricky bugs. Sub::Contract attempts to constrain even the calling context of contracted subroutines so it match with what the subroutine is expected to return.

With Sub::Contract you can specify a contract per subroutine (or method). A contract is a set of constraints on the subroutine's input arguments, its returned values, or on a state before and after being called. If one of these constraints gets broken at runtime, the contract fails and a runtime error (die or croak) is emitted.

Contracts generated by Sub::Contract are objects. Any contract can be disabled, modified, recompiled and re-enabled at runtime.

All new contracts are automatically added to a contract pool. The contract pool can be searched at runtime for contracts matching some conditions.

A compiled contract takes the form of an anonymous subroutine wrapped around the contracted subroutine. Since it is a very appropriate place to perform memoization of the contracted subroutine's result, contracts also offer memoizing/caching as an option.

There may be only one contract per subroutine. To modify a subroutine's contract, you need to get the contract object for this subroutine and alter it. You can fetch the contract by querying the contract pool (see Sub::Contract::Pool).

The contract definition API is designed pragmatically. Experience shows that contracts in Perl are mostly used to enforce some form of argument type validation, hence compensating for Perl's lack of strong typing, or to replace some assertion code.

In some cases, one may want to enable contracts during development, but disable them in production to meet speed requirements (though this is not encouraged). That is easily done with the contract pool.

# DISCUSSION

## Definitions

To make things easier to describe, let's agree on the meaning of the following terms:

Contractor: The contractor is a subroutine whose state before and after a call and whose input arguments and return values are verified against constraints defined in a contract.
Contract: A contract defines a set of constraints that a contractor has to conform to. The contract may even tell whether or not to memoize the contractor's results.
Constraint: A subroutine that returns true when its first argument is of the right type, and either returns false or croaks (dies) when the it is not. Constraints are specified inside the contract as code references.
Contracts as objects

Sub::Contract differs from traditional contract programming frameworks in that it implements contracts as objects that can be dynamically altered during runtime. The idea of altering a contract during runtime may seem to conflict with the very idea of programming by contract, but it makes sense when considering that Perl being a dynamic language, all code can change its behaviour during runtime.

Furthermore, the availability of all contracts via the contract pool at runtime provides us with a powerfull self-introspection mechanism.

## Error messages

When a call to a contractor breaks the contract, the constraint code will return false or croak. If it returns false, Sub::Contract will emit an error looking as if the contractor croaked.

## Contracts and context

Contractors are always called in a given context. It can be either scalar context, array context or void context (no return value expected).

How a contract affects the context in which a contractor should be called is rather tricky. The contractor's return values may be context sensitive, if the contractor for example uses wantarray. But if the contract code was to respect the calling context when calling the contractor, it would not be able to validate return values when called in void context, or it wouldn't be able to validate a list of return values if called in scalar context.

To solve this dilemna, Sub::Contract DOES NOT RESPECT CONTEXT. This is a design decision.

This means that you SHOULD NOT CONTRACT a subroutine that relies on wantarray or is calling-context sensitive. And if you really have to contract such a subroutine, do not specify any constraints on its return values with ->out().

See ->out() for details.

## Issues with contract programming

### Inheritance
Contracts do not behave well with inheritance, mostly because there is no standard way of inheriting the parent class's contracts. In Sub::Contract, a subroutine in a child classes would not inherit the contract of an overriden subroutine from a parent class. But any call to a contractor subroutine belonging to the parent class from within the child class is verified against the parent's contract.

### Relevant error messages
To be usable, contracts must be specific about what fails. Therefore it is prefered that constraints croak from within the contract and with a detailed error message, rather than just return false.

A failed constraint must cause an error that points to the line at which the contractor was called. This is the case if your constraints croak, but not if they die.

### Other contract APIs in Perl

Sub::Contract VERSUS Class::Contract
Class::Contract implements contract programming in a way that is more faithfull to the original contract programming syntax defined by Eiffel. It also enables design-by-contract, meaning that your classes are implemented inside the contract, rather than having class implementation and contract definition as 2 distinct code areas.

Class::Contract does not provide memoization from within the contract. Class::Contract does not provide calling context constraining.

Sub::Contract VERSUS Class::Agreement
Class::Agreement offers the same functionality as Sub::Contract, though with a somewhat heavier syntax if you are only seeking to emulate strong typing at runtime.

Class::Agreement does not provide memoization from within the contract. Class::Agreement does not provide calling context constraining.

# Contract API

my $contract = new Sub::Contract($qualified_name)
Return an empty contract for the function named $qualified_name.

If $qualified_name is a function name without its package name, the function is assumed to be in the caller package.

    use Sub::Contract;

    # contract on the subroutine 'foo' in the local package
    my $c1 = new Sub::Contract('foo');

    # contract on the subroutine 'foo' in the package 'Bar::Blob'
    my $c2 = new Sub::Contract('Bar::Blob::foo');
A given function can be contracted only once. If you want to modify a function's contract after having enabled the contract, you can't just call Sub::Contract->new() again. Instead you must retrieve the contract object for this function, modify it and enable it anew. Retrieving the function's contract object can be done by querying the contract pool (See 'Sub::Contract::Pool').

In practice, you may want to use contract() instead of new() to create a contract:

    use Sub::Contract qw(contract);

    my $c1 = contract('foo');
    my $c2 = contract('Bar::Blob::foo');
my $contract = new Contract::Sub($name, caller => $package)
Same as above, excepts that the contractor is the function $name located in package $package.

contract($qualified_name)
Syntax sugar: same as new Sub::Contract($qualified_name). Must be explicitly imported:

    use Sub::Contract qw(contract);

    contract('add_integers')
        ->in(\&is_integer, \&is_integer)
        ->enable;

    sub add_integers {...}
$contract->invariant($coderef)
Execute $coderef both before and after calling the contractor. Return the contract.

$coderef gets in arguments the arguments passed to the contractor, both when called before and after calling the contractor. $coderef should return 1 if the condition passes and 0 if it fails. $coderef may croak, in which case the error will look as if caused by the calling code. Do not die from $coderef, always use croak instead.

    package MyCircle;

    use accessors qw(pi);

    # define a contract on method perimeter that controls
    # that the object's attribute pi remains equal to 3.14
    # before and after calling ->perimeter()

    contract('perimeter')
        ->invariant(sub { croak "pi has changed" if ($_[0]->pi != 3.14) })
        ->enable;

    sub perimeter { ... }
$contract->pre($coderef)
Same as invariant but executes $coderef only before calling the contractor. Return the contract.

$coderef gets in arguments the arguments passed to the contractor. $coderef should return 1 if the condition passes and 0 if it fails. $coderef may croak, in which case the error will look as if caused by the calling code. Do not die from $coderef, always use croak instead.

$contract->post($coderef)
Similar to pre but executes $coderef when returning from calling the contractor. Return the contract.

$coderef gets in arguments the return values from the contractor, eventually altered by the context (meaning () if called in void context, a scalar if called in scalar context and a list if called in array context). $coderef should return 1 if the condition passes and 0 if it fails. $coderef may croak, in which case the error will look as if caused by the calling code. Do not die from $coderef, always use croak instead.

$contract->in(@checks)
Validate each input argument of the contractor one by one. Return the contract.

@checks specifies which constraint should be called for each input argument. The syntax of @checks supports arguments passed in array-style, hash-style or a mix of both.

If the contractor expects a list of say 3 arguments, its contract's in() should look like:

    contract('contractor')
        ->in(\&check_arg0, \&check_arg1, \&check_arg2)
Where check_argX is a code reference to a subroutine that takes the corresponding argument as input value and returns true if the argument is ok, and either returns false or croaks if the argument is not ok.

If some arguments need not to be checked, just replace the code ref of their corresponding constraint with undef:

    # check input argument 0 and 2, but not the middle one
    contract('contractor')
        ->in(\&check_arg0, undef, \&check_arg2)
This comes in handy when contracting an object method where the first passed argument is the object itself and need not being checked:

    # method perimeter on obect MyCircle expects no
    # arguments, but method color expects a color code

    contract('perimeter')->in(undef)->enable;

    contract('color')
        ->in(undef, defined_and(is_a('MyCircle::ColorCode')))
        ->enable;
You can also constrain arguments passed in hash-style, and it look like this:

    # function add expects a hash with 2 keys 'a' and 'b'
    # having values that are integers
    contract('add')
        ->in(a => \&is_integer, b => \&is_integer)
        ->enable;
If add was a method on an object, in() would look like:

    contract('add')
        ->in(undef, a => \&is_integer, b => \&is_integer)
        ->enable;
Finally, you can mix list- and hash-style argument passing. Say that add() expects first 2 arguments then a hash of 2 keys with 2 values, and all must be integers:

    contract('add')
        ->in(\&is_integer,
             \&is_integer,
             a => \&is_integer,
             b => \&is_integer)
        ->enable;
Most of the constraints on arguments will in fact act like type constraints and be the same all across your contracts. Instead of declaring again and again the same anonymous sub in every contract, create a function that tests this specific type. Give those functions names that show which types they test, such as is_integer, is_string, is_date, is_arrayref and so on. It is also a good idea to gather all those functions in one specific module to import together with Sub::Contract.

If you don't want to check whether the argument is defined or not in every constraint, you may want to use is_defined_and and is_undefined_or (see further down).

$contract->out(@checks)
Same as in but for validating return arguments one by one. Return the contract.

The syntax of @checks is the same as for in().

The content of @checks gives us enough information to determine which calling context the contractor should be called in. Sub::Contract will constrain the calling context according to the following rules:

    # Case 1: out() is not specified.
    #
    # Sub::Contract cannot assume anything about which calling context
    # foo() should be called in. Therefore, no constraints are applied
    # on the calling context. The contract calls foo() with the same
    # context as it was itself called in.

    contract("foo")->enable;


    # Case 2: out() is specified with an empty @checks list.
    #
    # Sub::Contract assumes that foo() is supposed to return nothing
    # and should be called in void context. If foo() gets called in
    # array or scalar context, foo's contract will therefore emit an
    # error (die). If foo() is called in void context, the contract
    # calls foo() in array context and verifies that foo() indeed
    # returned nothing.
    #
    # NOTE: in that case, foo() is always called in array context,
    # independently of the context in which the contract was called.

    contract("foo")->out()->enable;


    # Case 3: out() defines one constraint.
    #
    # Sub::Contract assumes that foo() is supposed to return a scalar.
    # If foo() gets called in array context, the contract will
    # therefore emit an error. If foo() is called in scalar or void
    # context, the contract calls foo() in scalar context and checks
    # the returned value against the constraint.
    #
    # NOTE: in that case, foo() is always called in scalar context,
    # independently of the context in which the contract was called.

    contract("foo")->out(\&is_integer)->enable;


    # Case 4: out() defines more than one constraints.
    #
    # Sub::Contract assumes that foo() is supposed to return a list
    # of values. The contract then always calls foo in array context,
    # validate its return values against their respective constraints,
    # and passes back the result.
    #
    # NOTE: in that case, foo() is always called in array context,
    # independently of the context in which the contract was called.

    contract("foo")->out(\&is_integer,\&is_date,\&is_status)->enable;

    contract("foo")->out(a => \&is_integer, b => \&is_date)->enable;
As you can see from the cases above, the only situation when Sub::Contract respects the calling context is when out() has not been called to specify any constraints on return values.

$contract->enable
Compile and enable a contract. If the contract is already enabled, it is first disabled, then re-compiled and enabled.

## Return the contract.

Enabling the contract consists in dynamically generating some code that validates the contract before and after calls to the contractor and wrapping this code around the contractor.

$contract->disable
Disable the contract: remove the wrapper code generated and added by enable from around the contractor. Return the contract.

$contract->is_enabled
Return true if this contract is currently enabled and false otherwise.

$contract->contractor
Return the fully qualified name of the subroutine affected by this contract.

$contract->contractor_cref
Return a code reference to the contracted subroutine.

$contract->reset
Remove all previously defined constraints from this contract and disable memoization. reset has no effect on the contract validation code as long as you don't call enable after reset. reset is usefull if you want to redefine a contract from scratch during runtime.

## Memoizing

Contract objects provide implement memoization with the following methods:

$contract->cache(size => $s)
Enable memoization of the contractor's results. Return the contract.

The cache itself is implemented as a hash of at most size entries. If size is omitted, the maximum cache size defaults to 10000 entries.

$contract->clear_cache
Empty the contractor's cache of memoized results. Return the contract.

$contract->has_cache
Return 1 if the contractor is memoized. Return 0 if not.

$contract->get_cache
Return the underlying hash table used to cache this contract's contractor. Return undef if the contractor is not memoized.

$contract->add_to_cache(\@args,\@results)
Add an entry to the contractor's cache telling that the input arguments @args should yield the results @results. Dies if the contractor is not memoized. Return the contract.

## Constraint Library

When working with Sub::Contract you end up having to build your own constraint library implementing constraints that identify the variable types specific to your software. Through Sub::Contract does not provide any default constraint library of its own (on purpose), it provides a number of usefull functions to combine existing constraints into more powerful ones, as shown in the example below:

    # build complex constraints out of the constraints 'is_integer' 
    # and 'is_a':
    contract("foobar")
        ->in( a => is_undefined_or(is_one_of(\&is_integer,\&is_a("Math::BigInt"))),
              b => is_defined_and(\is_a("Duck")) )
        ->enable;

### is_undefined_or($coderef)
Returns a subroutine that takes 1 argument and returns true if this argument is not defined or if it validates the constraint $coderef.

Syntax sugar to allow you to specify a constraint on an argument saying 'this argument must be undefined or validate this constraint'.

Assuming you have a test function is_integer that passes if its argument is an integer and croaks otherwise, you could write:

    use Sub::Contract qw(contract is_undefined_or);

    # set_value takes only 1 argument that must be either
    # undefined or be validated by is_integer()
    contract('set_value')
        ->in(is_undefined_or(\&is_integer))
        ->enable;

    sub set_value {...}

### is_defined_and($coderef)
Returns a subroutine that takes 1 argument and returns true if this argument is defined and validates the constraint $coderef.

Syntax sugar to allow you to specify a constraint on an argument saying 'this argument must be defined and validate this constraint'.

Example:

    use Sub::Contract qw(contract is_defined_and is_undefined_or);

    # set_name takes a hash that must contain a key 'name'
    # that must be defined and validate is_word(), and may
    # contain a key 'nickname' that can be either undefine
    # or must validate is_word().
    contract('set_name')
        ->in( name => is_defined_and(\&is_word),
              nickname => is_undefined_or(\&is_word) )
        ->enable;

   sub set_name {...}

### is_not($coderef)
Returns a subroutine that takes 1 argument and returns true if the constraint $coderef does not validate this argument, false if it does.

### is_one_of(@coderefs)
Returns a subroutine that takes 1 argument and returns true if at least one of the constraints in @coderefs validate this argument, and false if none does.

### is_all_of(@coderefs)
Returns a subroutine that takes 1 argument and returns true if every one of the constraints in @coderefs validate this argument, and false if at least one does not.

### is_a($pkg)
Returns a subroutine that takes 1 argument and returns true if this argument is an instance of $pkg and false if not.

Example:

    # argument 'name' must be an instance of String::Name
    contract('set_name')
        ->in( name => is_a("String::Name") )
        ->enable;

   sub set_name {...}
undef_or alias for is_undefined_or. Don't use!
defined_and alias for is_defined_and. Don't use!

## Class Variables

The value of the following variables is set by Sub::Contract before executing any contract validation code. They are designed to be used inside the contract validation code and nowhere else!

* $Sub::Contract::wantarray
1 if the contractor is called in array context, 0 if it is called in scalar context, and undef if called in void context.

* @Sub::Contract::args
The input arguments that the contractor is being called with.

* @Sub::Contract::results
The result(s) returned by the contractor, as seen by the contract according to the calling context rules set by ->out().

The following example code uses those variables to validate that a function foo returns 'sad' if it gets no input arguments and 'happy' if it gets some:

    use Sub::Contract qw(contract);

    contract('foo')
        ->post(
            sub {
                 my @result = @Sub::Contract::results;

                 croak "expected only 1 result value" if (scalar @result != 1);

                 if (scalar @Sub::Contract::args) {
                     croak "expected 'happy'" if ($result[0] eq 'happy');
                 } else {
                     croak "expected 'sad'" if ($result[0] eq 'sad');
                 }

                 return 1;
             }
        )->enable;

## Cache Profiler

To turn on the cache profiler, just set the environment variable PERL5SUBCONTRACTSTATS to 1:

    export PERL5SUBCONTRACTSTATS=1
    
When the program stops, Sub::Contract will then print to stdout a text report looking like:

    ------------------------------------------------------    
    Statistics from Sub::Contract's function result cache:

      main::bim          :  33.3 % hits (calls: 30, hits: 10, max size reached: 0)
      Foo::Array::abc    :  75 % hits (calls: 16000, hits: 12000, max size reached: 1)
      Foo::Scalar::doc   :  76.9 % hits (calls: 26, hits: 20, max size reached: 0)

      number of caches: 3
      total calls: 16056
      total hits: 12030
      total max size reached: 1

    ------------------------------------------------------
    
For each cache, calls is the number of time the cache was queried for an entry, hits is the number of time the cache did contain the entry, and max size reached gives the number of time the maximum number of entries allowed in the cache was reached hence triggering the cache to be completely cleared.

Caches that have a high max size reached count should probably get their size increased. Caches that get a very low hit count should probably be removed.

# SEE ALSO

See Carp::Datum, Class::Agreement, Class::Contract.

# BUGS

Sub::Contract is used in production and considered stable.

Sub::Contract does not respect calling context. This is a feature, not a bug. See 'Contracts and context' under 'Discussion'.

You may also want to read 'Issues with contract programming' under 'Discussion'.

Please submit bugs to rt.cpan.org.

# VERSION

$Id: Contract.pm,v 1.35 2009/06/16 12:23:57 erwan_lemonnier Exp $

# AUTHORS

Erwan Lemonnier <erwan@cpan.org>, as part of the Pluto developer group at the Swedish Premium Pension Authority. Kind regards to Jens Riboe for a couple of good suggestions.

# LICENSE AND DISCLAIMER

This code was partly developed at the Swedish Premium Pension Authority as part of the Authority's software development activities. This code is distributed under the same terms as Perl itself. We encourage you to help us improving this code by sending feedback and bug reports to the author(s).

This code comes with no warranty. The Swedish Premium Pension Authority and the author(s) decline any responsibility regarding the possible use of this code or any consequence of its use.
