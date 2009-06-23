package CatalystX::LeakChecker;

use Moose::Role;
use PadWalker 'closed_over';
use Scalar::Util 'weaken', 'isweak';;
use aliased 'Data::Visitor::Callback', 'Visitor';

use namespace::autoclean -also => [qw/Visitor visit_code format_table/];

sub visit_code {
    my ($self, $code, $weak_ctx, $leaks) = @_;
    my $vars = closed_over $code;

    while (my ($name, $val) = each %{ $vars }) {
        next unless $weak_ctx == ${ $val };
        next if isweak ${ $val };
        push @{ $leaks }, $name;
    }

    return $code;
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

sub format_table {
    my @leaks = @_;
    my $t = Text::SimpleTable->new([ 70, 'Variable' ]);
    $t->row($_) for @leaks;
    return $t->draw;
}

sub found_leaks {
    my ($ctx, @leaks) = @_;
    my $msg = "Leaked context:\n" . format_table(@leaks);
    $ctx->log->debug($msg) if $ctx->debug;
}

1;
