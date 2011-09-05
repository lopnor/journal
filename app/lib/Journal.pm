package Journal;
use 5.12.0;
use parent 'Soffritto::Web';
use Plack::Util::Accessor qw(tz);
use Text::Markdown ();
use Text::Hatena;
use DateTime;
use DateTime::TimeZone;
use XML::Feed;

our $VERSION = 0.01;

sub prepare {
    my $self = shift;
    $self->tz(DateTime::TimeZone->new(name => 'local'));
}

sub dispatch {
    my ($self, $req) = @_;
    given ($req->path_info) {
        when (m{^/writer(/(?<id>\d+)?|)$}) { return 'writer_' . $req->method, $+{id} }
        when (m{^/$}) { return 'page', 1 }
        when (m{^/page/(?<page>\d+)$}) { return 'page', $+{page} }
        when (m{^/entry/(?<id>\d+)$}) { return 'entry', $+{id} }
        when (m{^/feed$}) { return 'feed' }
    }
}

sub writer_GET {
    my ($self, $req, $id) = @_;
    my $entry = {};
    if ($id) {
        $entry = $self->db->find('entry', '*', {id => $id})
            or return $self->error(404);
    }
    $self->render('writer', {entry => $entry});
}

sub writer_POST {
    my ($self, $req, $id) = @_;
    my $params = $req->parameters->as_hashref;
    if (delete $params->{delete}) {
        $self->db->delete('entry', {id => $id}) if $id;
        return $req->redirect_to('/');
    } elsif ($id) {
        $self->db->update('entry', $params, {id => $id});
        return $req->redirect_to("/entry/$id");
    } else {
        my ($stmt, @bind) = $self->db->insert(
            'entry', {
                %$params,
                posted_at => time,
            }
        );
        $id = $self->db->max('entry', 'id');
        return $req->redirect_to("/entry/$id");
    }
}

sub page {
    my ($self, $req, $page) = @_;
    $page ||= 1;

    my $entries = $self->db->select(
        'entry', '*', undef, {-desc => 'id'}, 10, 10 * ($page - 1)
    );
    $self->render('page',
        { page => $page, entries => [map {$self->deflate($_) } @$entries] }
    );
}

sub entry {
    my ($self, $req, $id) = @_;
    my $entry = $self->db->find( 'entry', '*', {id => $id} )
        or return $self->error(404);
    $self->render('entry', {entry => $self->deflate($entry)})
}

sub feed {
    my ($self, $req) = @_;
    my $entries = $self->db->select('entry', '*', undef, {-desc => 'id'}, 10, 0);
    my $feed = XML::Feed->new('RSS');
    $feed->title('soffritto::journal');
    $feed->description('');
    $feed->link($req->base->as_string);
    for my $item (map {$self->deflate($_)} @$entries) {
        my $entry = XML::Feed::Entry->new('RSS');
        $entry->title($item->{subject});
        $entry->link($req->uri_for("/entry/$item->{id}"));
        $entry->content($item->{html});
        $entry->issued($item->{posted_at});
        $feed->add_entry($entry);
    }
    $self->respond($feed->as_xml, 'application/rss+xml; charset=utf-8');
}

sub deflate {
    my ($self, $entry) = @_;
    $entry->{posted_at} = DateTime->from_epoch(
        epoch => $entry->{posted_at},
        time_zone => $self->tz,
    );
    $entry->{html} = do {
        if ($entry->{format} eq 'hatena') {
            Text::Hatena->parse($entry->{body})
        } elsif ($entry->{format} eq 'markdown') {
            Text::Markdown::markdown($entry->{body})
        } else {
            $entry->{body}
        }
    };
    return $entry;
}

1;
__END__

=pod

=head1 NAME 

Journal - webapp for journal.soffritto.org

=cut
