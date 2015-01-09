package Class::Accessor::Lazy::Fast;
use strict;
$Class::Accessor::Lazy::Fast::VERSION = '0.34';
use Exporter 'import';
use Class::Accessor::Fast;

our @EXPORT;

push @EXPORT, 'fast_accessors';
sub fast_accessors{
    my $self = shift;
    my $class = ref $self || $self;

    no strict 'refs';
    
    *{"${class}::make_accessor"} = \&Class::Accessor::Fast::make_accessor;
    *{"${class}::make_ro_accessor"} = \&Class::Accessor::Fast::make_ro_accessor;
    *{"${class}::make_wo_accessor"} = \&Class::Accessor::Fast::make_wo_accessor;
    *{"${class}::make_lazy_accessor"} = \&Class::Accessor::Lazy::Fast::make_accessor;
    *{"${class}::make_lazy_ro_accessor"} = \&Class::Accessor::Lazy::Fast::make_ro_accessor;
    *{"${class}::make_lazy_wo_accessor"} = \&Class::Accessor::Lazy::Fast::make_wo_accessor;
    
    return $self;
}


sub make_accessor {
    my ($class, $field) = @_;

    return sub {
        my $self = shift;
        
        if(@_) 
        {
            $self->{'__lazy_inits'}->{$field} = 1 unless exists $self->{'__lazy_inits'}->{$field};
            return $self->{$field} = $_[0];
        } 
        else
        {
            unless (exists $self->{'__lazy_inits'}->{$field})
            {
                my $init_method = "_lazy_init_$field";
                $self->$init_method();
                
                $self->{'__lazy_inits'}->{$field} = 1;
            }

            return $self->{$field};
        }
    };
}

sub make_ro_accessor {
    my($class, $field) = @_;

    return sub {
        my $self = shift;

        if (@_) 
        {
            my $caller = caller;
            $self->_croak("'$caller' cannot alter the value of '$field' on objects of class '$class'");
        }
        else 
        {
            unless (exists $self->{'__lazy_inits'}->{$field})
            {
                my $init_method = "_lazy_init_$field";
                $self->$init_method();

                $self->{'__lazy_inits'}->{$field} = 1;
            }
            return $self->{$field};
        }
    };
}

# requires only for best_practice rw acessors
sub make_wo_accessor {
    my($class, $field) = @_;

    return sub {
        my $self = shift;

        unless (@_) 
        {
            my $caller = caller;
            $self->_croak("'$caller' cannot access the value of '$field' on objects of class '$class'");
        }
        else 
        {
            $self->{'__lazy_inits'}->{$field} = 1 unless exists $self->{'__lazy_inits'}->{$field};
            return $self->{$field} = $_[0];
        }
    };
}

1;