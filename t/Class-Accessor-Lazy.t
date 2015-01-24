#!/usr/bin/perl -It/

use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Class::Accessor::Lazy') };

use_ok('Foo');
use_ok('Bar');



#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
done_testing();
