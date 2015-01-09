#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Class::Accessor::Lazy' ) || print "Bail out!\n";
}

diag( "Testing Class::Accessor::Lazy $Class::Accessor::Lazy::VERSION, Perl $], $^X" );
