use 5.006;use strict;use warnings FATAL => 'all';use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Class::Accessor::Lazy',
    AUTHOR           => 'Alexandr Evstigneev <hurricup@evstigneev.com>',
    VERSION_FROM     => 'lib/Class/Accessor/Lazy.pm',
    ABSTRACT_FROM    => 'lib/Class/Accessor/Lazy.pm',
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::Harness' => 0,
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Class::Accessor' => 0,
        'Class::Accessor::Fast' => 0,
    },
);
