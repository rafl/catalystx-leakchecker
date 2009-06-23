package TestApp::Controller::Affe;

use Moose;
use Scalar::Util 'weaken';
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

sub no_closure : Local {
    my ($self, $ctx) = @_;
    $ctx->response->body('no_closure');
}

sub leak_closure : Local {
    my ($self, $ctx) = @_;
    $ctx->stash(leak_closure => sub {
        $ctx->response->body('from leaky closure');
    });
    $ctx->response->body('leak_closure');
}

sub weak_closure : Local {
    my ($self, $ctx) = @_;
    my $weak_ctx = $ctx;
    weaken $weak_ctx;
    $ctx->stash(weak_closure => sub {
        $weak_ctx->response->body('from weak closure');
    });
    $ctx->response->body('weak_closure');
}

1;
