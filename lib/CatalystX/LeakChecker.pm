package CatalystX::LeakChecker;

use Moose::Role;
use B::Deparse;
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
