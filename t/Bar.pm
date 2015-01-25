package Bar;
use strict; use warnings;
use parent 'Class::Accessor::Lazy';

__PACKAGE__->follow_best_practice
    ->fast_accessors
    ->mk_accessors('rw_accessor')
    ->mk_ro_accessors('ro_accessor')
    ->mk_wo_accessors('wo_accessor')
    ->mk_lazy_accessors('rw_accessor_lazy')
    ->mk_lazy_ro_accessors('ro_accessor_lazy');

sub _lazy_init_rw_accessor_lazy
{
    my $self = shift;
    $self->{'rw_accessor_lazy'} = 'rw lazy init';
}

sub _lazy_init_ro_accessor_lazy
{
    my $self = shift;
    $self->{'ro_accessor_lazy'} = 'ro lazy init';
}

1;