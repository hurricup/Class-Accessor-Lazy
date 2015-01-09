package Class::Accessor::Lazy;
use strict;
use 5.006;
use base 'Class::Accessor';
$Class::Accessor::Lazy::VERSION = '0.35';
use Class::Accessor::Lazy::Original;
use Class::Accessor::Lazy::Fast;
use Carp qw(confess);

sub new
{
    my($proto, $fields) = @_;
    my($class) = ref $proto || $proto;

    my $self = $class->SUPER::new($fields);
    $self->{'__lazy_inits'} = {}; 

    return $self;
}

sub mk_lazy_accessors {
    my($self, @fields) = @_;

    return $self->_mk_lazy_accessors('rw', @fields);
}
sub mk_lazy_ro_accessors {
    my($self, @fields) = @_;

    return $self->_mk_lazy_accessors('ro', @fields);
}


*make_lazy_accessor = \&Class::Accessor::Lazy::Original::make_accessor;
*make_lazy_ro_accessor = \&Class::Accessor::Lazy::Original::make_ro_accessor;
*make_lazy_wo_accessor = \&Class::Accessor::Lazy::Original::make_wo_accessor;

{
    no strict 'refs';

    sub follow_best_practice {
        my $self = shift;
        my $class = ref $self || $self;
        
        $class->SUPER::follow_best_practice();
        
        return $self;
    }

    sub _mk_accessors {
        my $self = shift;
        my $class = ref $self || $self;
        
        $class->SUPER::_mk_accessors(@_);
        
        return $self;
    }
    
    sub _mk_lazy_accessors {
        my $self = shift;
        my($access, @fields) = @_;
        my $class = ref $self || $self;
        my $ra = $access eq 'rw' || $access eq 'ro';
        my $wa = $access eq 'rw' || $access eq 'wo';

        foreach my $field (@fields) {
            my $accessor_name = $self->accessor_name_for($field);
            my $mutator_name = $self->mutator_name_for($field);
            if( $accessor_name eq 'DESTROY' or $mutator_name eq 'DESTROY' ) {
                $self->_carp("Having a data accessor named DESTROY  in '$class' is unwise.");
            }
            
            my $lazy;
            if ($accessor_name eq $mutator_name) {
                my $accessor;
                if ($ra && $wa) {
                    $accessor = $self->make_lazy_accessor($field);
                    $lazy = 1;
                } elsif ($ra) {
                    $accessor = $self->make_lazy_ro_accessor($field);
                    $lazy = 1;
                } else {
                    $accessor = $self->make_lazy_wo_accessor($field);
                }
                
                my $fullname = "${class}::$accessor_name";
                my $subnamed = 0;
                unless (defined &{$fullname}) {
                    subname($fullname, $accessor) if defined &subname;
                    $subnamed = 1;
                    *{$fullname} = $accessor;
                }
                if ($accessor_name eq $field) {
                    # the old behaviour
                    my $alias = "${class}::_${field}_accessor";
                    subname($alias, $accessor) if defined &subname and not $subnamed;
                    *{$alias} = $accessor unless defined &{$alias};
                }
            } else {
                my $fullaccname = "${class}::$accessor_name";
                my $fullmutname = "${class}::$mutator_name";
                if ($ra and not defined &{$fullaccname}) { # guess, we need warning here, that accessor exists
                    my $accessor = $self->make_lazy_ro_accessor($field);
                    $lazy = 1;
                    subname($fullaccname, $accessor) if defined &subname;
                    *{$fullaccname} = $accessor;
                }
                if ($wa and not defined &{$fullmutname}) { # guess, we need warning here, that mutator exists
                    my $mutator = $self->make_lazy_wo_accessor($field);
                    subname($fullmutname, $mutator) if defined &subname;
                    *{$fullmutname} = $mutator;
                }
            }
            
            if( $lazy )
            {
                my $init_method = "${class}::_lazy_init_$field";
                unless (defined &{$init_method} ){
                    $self->_croak("Unable to create lazy accessor '$field' without defined init method $init_method");
                }
            }
        }
        return $self;
    }
}

1;

__END__
=pod

=head1 NAME

  Class::Accessor::Lazy - Automated accessor generation with lazy accessors and fast mode support.

=head1 SYNOPSIS

    package Foo;
    use base qw(Class::Accessor::Lazy);

    Foo->follow_best_practice->fast_accessors;

    Foo->mk_accessors(qw(name role salary))
        ->mk_lazy_accessors(qw(work_history));

    ...

    sub _lazy_init_work_history
    {
    ... resourseful history fething from database
    }
    
    # Meanwhile, in a nearby piece of code!
    # Class::Accessor::Lazy provides new().
    my $mp = Foo->new({ name => "Marty", role => "JAPH" });

    my $job = $mp->role;  # gets $mp->{role}
    $mp->salary(400000);  # sets $mp->{salary} = 400000 # I wish

    # like my @info = @{$mp}{qw(name role)}
    my @info = $mp->get(qw(name role));

    # $mp->{salary} = 400000
    $mp->set('salary', 400000);


=head1 DESCRIPTION

This module merges the power of two separate modules: L<Class::Accessor> and 
L<Class::Accessor::Fast>. Additionaly providing methods to create lazy 
properties.

It can provide accessors creation methods for your class using two algorithms, 
provided by modules above. But now you may change algorithm in 
the code:

    package Foo;
    use base qw(Class::Accessor::Lazy);

    Foo->follow_best_practice;

    Foo->mk_accessors(slow_accessor);

    Foo->fast_accessors;

    Foo->mk_accessors(fast_accessor);

    # or even
    
    Foo->follow_best_practice
        ->mk_accessors(slow_accessor)
        ->fast_accessors
        ->mk_accessors(fast_accessor);
  
Main documentation may be found on L<Class::Accessor> and 
L<Class::Accessor::Fast> pages.

The main extension of this module is possibility to make lazy properties, which
will be inited on first get operation (if there was no write before).

Such methods are useful for database representation classes, where related
data may not be read at all and there is no need to fetch it from database.

For example, there are C<Shop> class and C<Employee> class. Each C<Shop> has 
property C<employees>, which contains a reference to C<Employee> objects list. 
But, you could fetch Shop object from database just to check C<income> property
and no don't need information about employees at all. In this case, reading 
employees list and creating list of C<Employee> objects makes absolutely no
sense.

But, if you want to get access to them, they should be read from database. And
here are lazy properties comes:

    package Shop;
    use base 'Class::Accessor::Lazy';
    
    Shop->follow_best_practice              # use set/get for accessors/mutators
        ->fast_accessors                    # use Class::Acessor::Fast algorithm
        ->mk_accessors('income')            # regular property
        ->mk_lazy_accessors('employees');   # lazy property
        
    ...
        
    sub _lazy_init_employees
    {
        # here we are reading employees from database and saving them in 
        # property directly or using mutator set_employees
    }

On first C<get_employees> invocation, method C<Shop::_lazy_init_employees> 
will be invoked automatically, to allow your class to read related data from 
database, for example, and store it in property. 

IMPORTANT: every lazy property of the class MUST have related init method. The
name of such method is C<_lazy_init_{property name}>. 

=head1 NEW METHODS

There are couple of new methods in addition to L<Class::Accessor>s ones. Also, 
class methods now returns C<$self> and you may use chain calls.

=head2 fast_acessors 

Enables using L<Class::Accessor::Fast> accessors generators.

=head2 original_acessors 

Enables using L<Class::Accessor> accessors generators.

=head2 mk_lazy_accessors 

Same as C<mk_accessors>, but creating lazy ones.

=head2 mk_lazy_ro_accessors 

Same as C<mk_ro_accessors>, but creating lazy ones.

there is no C<mk_lazy_wo_accessors> method.


=head1 EFFICIENCY

 Accessors benchmark:
 Benchmark: timing 20000000 iterations of Acessor, AcessorF, Direct, Lazy, LazyF...
   Acessor: 12 wallclock secs (11.34 usr +  0.00 sys = 11.34 CPU) @ 1763512.92/s (n=20000000)
  AcessorF:  6 wallclock secs ( 5.71 usr +  0.00 sys =  5.71 CPU) @ 3502626.97/s (n=20000000)
    Direct:  1 wallclock secs ( 0.78 usr +  0.00 sys =  0.78 CPU) @ 25641025.64/s (n=20000000)
      Lazy: 14 wallclock secs (13.85 usr +  0.00 sys = 13.85 CPU) @ 1443730.60/s (n=20000000)
     LazyF:  9 wallclock secs ( 8.71 usr +  0.00 sys =  8.71 CPU) @ 2297530.16/s (n=20000000)
     
 Mutators benchmark: 
 Benchmark: timing 20000000 iterations of Acessor, AcessorF, Direct, Lazy, LazyF...
   Acessor: 16 wallclock secs (15.26 usr +  0.00 sys = 15.26 CPU) @ 1310959.62/s (n=20000000)
  AcessorF:  8 wallclock secs ( 7.91 usr +  0.00 sys =  7.91 CPU) @ 2528764.70/s (n=20000000)
    Direct:  2 wallclock secs ( 1.50 usr +  0.00 sys =  1.50 CPU) @ 13351134.85/s (n=20000000)
      Lazy: 19 wallclock secs (18.83 usr +  0.00 sys = 18.83 CPU) @ 1062191.30/s (n=20000000)
     LazyF:  9 wallclock secs (10.53 usr +  0.00 sys = 10.53 CPU) @ 1899335.23/s (n=20000000)
     
Direct means direct access to the object property, and F suffix means using C<fast_accessors>.

=head1 AUTHORS

Copyright 2014 Alexandr Evstigneev <hurricup@gmail.com>

Based on C<Class::Accessor> and C<Class::Accessor::Fast> code.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=head1 SEE ALSO

See L<Class::Accessor>, L<Class::Accessor::Fast> and L<Class::Accessor::Faster> if speed is more
important than flexibility.

These are some modules which do similar things in different ways
L<Class::Struct>, L<Class::Methodmaker>, L<Class::Generate>,
L<Class::Class>, L<Class::Contract>, L<Moose>, L<Mouse>

=cut
