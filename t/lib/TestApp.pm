package TestApp;

use Moose;
use MooseX::AttributeHelpers;
use MooseX::Types::Moose qw/ArrayRef/;
use namespace::autoclean;

extends 'Catalyst';
with 'CatalystX::LeakChecker';

has leaks => (
    metaclass => 'Collection::Array',
    is        => 'ro',
    isa       => ArrayRef,
    default   => sub { [] },
    provides  => {
        push  => 'add_leaks',
        count => 'count_leaks',
        first => 'first_leak',
    },
);

sub found_leaks {
    my ($ctx, @leaks) = @_;
    $ctx->add_leaks(@leaks);
}

__PACKAGE__->setup;

1;
