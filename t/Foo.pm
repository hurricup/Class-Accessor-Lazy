package Foo;
use strict; use warnings;
use parent 'Class::Accessor::Lazy';

__PACKAGE__->follow_best_practice
    ->original_accessors
    ->mk_accessors('rw_accessor')
    ->mk_ro_accessors('ro_accessor')
    ->mk_wo_accessors('rw_accessor')
    ->mk_lazy_accessors('rw_accessor_lazy')
    ->mk_lazy_ro_accessors('ro_accessor_lazy');

sub _lazy_init_rw_accessor_lazy
{
    my $self = shift;
    $self->{'rw_accessor_lazy'} = 'Foo rw lazy init';
}

sub _lazy_init_ro_accessor_lazy
{
    my $self = shift;
    $self->{'ro_accessor_lazy'} = 'Foo ro lazy init';
}

1;