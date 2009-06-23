use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test 'TestApp';

is(get('/affe/no_closure'), 'no_closure');
is(get('/affe/leak_closure'), 'leak_closure');
is(get('/affe/weak_closure'), 'weak_closure');

done_testing;
