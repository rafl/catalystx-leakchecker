package TestApp;

use Moose;
use namespace::autoclean;

extends 'Catalyst';
with 'CatalystX::LeakChecker';

__PACKAGE__->setup;

1;
