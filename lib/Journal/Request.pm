package Journal::Request;
use 5.12.0;
use parent 'Plack::Request';
use Encode ();
use URI::WithBase;

sub normal_response {
    my ($self, $body, $ct) = @_;
    $ct ||= 'text/html; charset=utf8';
    return $self->new_response(
        200,
        ['Content-Type' => $ct],
        [Encode::encode_utf8($body)],
    );
}

sub uri_for {
    my ($self, $path, $args) = @_;
    my $uri = URI::WithBase->new($path, $self->base);
    if ($args) {
        $uri->query_form(@$args);
    };
    return $uri->abs;
}

sub redirect_to {
    my ($self, @args) = @_;
    my $uri = $self->uri_for(@args);
    my $res = $self->new_response;
    $res->redirect($uri);
    return $res;
}

sub not_found {
    my ($self) = @_;
    return $self->new_response(
        404,
        ['Content-Type' => 'text/plain'],
        ['Not Found'],
    );
}

1;
