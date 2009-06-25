package CatalystX::LeakChecker;
# ABSTRACT: Debug memory leaks in Catalyst applications

use Moose::Role;
use B::Deparse;
use Text::SimpleTable;
use PadWalker 'closed_over';
use Scalar::Util 'weaken', 'isweak';;
use aliased 'Data::Visitor::Callback', 'Visitor';

sub visit_code {
    my ($self, $code, $weak_ctx, $leaks) = @_;
    my $vars = closed_over $code;

    while (my ($name, $val) = each %{ $vars }) {
        next unless $weak_ctx == ${ $val };
        next if isweak ${ $val };
        push @{ $leaks }, { code => $code, var => $name };
    }

    return $code;
}

sub deparse {
    my ($code) = @_;
    return B::Deparse->new->coderef2text($code);
}

sub format_table {
    my @leaks = @_;
    my $t = Text::SimpleTable->new([52, 'Code'], [ 15, 'Variable' ]);
    $t->row(@$_) for map { [deparse($_->{code}), $_->{var}] } @leaks;
    return $t->draw;
}

use namespace::clean -except => 'meta';

=head1 SYNOPSIS

    package MyApp;
    use namespace::autoclean;

    extends 'Catalyst';
    with 'CatalystX::LeakChecker';

    __PACKAGE__->setup;

=head1 DESCRIPTION

It's easy to create memory leaks in Catalyst applications and often they're
hard to find. This module tries to help you finding them by automatically
checking for common causes of leaks.

Right now, only one cause for leaks is looked for: putting a closure, that
closes over the Catalyst context (often called C<$ctx> or C<$c>), onto the
stash. More checks might be implemented in the future.

This module is intended for debugging only. I suggest to not enable it in a
production environment.

=method found_leaks(@leaks)

If any leaks were found, this method is called at the end of each request. A
list of leaks is passed to it. It logs a debug message

    [debug] Leaked context from closure on stash:
    .------------------------------------------------------+-----------------.
    | Code                                                 | Variable        |
    +------------------------------------------------------+-----------------+
    | {                                                    | $ctx            |
    |     package TestApp::Controller::Affe;               |                 |
    |     use warnings;                                    |                 |
    |     use strict 'refs';                               |                 |
    |     $ctx->response->body('from leaky closure');      |                 |
    | }                                                    |                 |
    '------------------------------------------------------+-----------------'

Override this method if you want leaks to be reported differently.

=cut

sub found_leaks {
    my ($ctx, @leaks) = @_;
    my $msg = "Leaked context from closure on stash:\n" . format_table(@leaks);
    $ctx->log->debug($msg) if $ctx->debug;
}

after finalize => sub {
    my ($ctx) = @_;
    my @leaks;

    my $weak_ctx = $ctx;
    weaken $weak_ctx;

    my $visitor = Visitor->new(
        code => sub { visit_code(@_, $weak_ctx, \@leaks) },
    );
    $visitor->visit($ctx->stash);
    return unless @leaks;

    $ctx->found_leaks(@leaks);
};

1;
