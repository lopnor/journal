package Journal::DB;
use Any::Moose;
extends 'Tatsumaki::Service';
use AnyEvent::DBI::Abstract::Limit;
use Text::Markdown;
#use Text::Xatena;
use Text::Hatena;
use DateTime::Format::Strptime;

has dbi => (is => 'rw', isa => 'AnyEvent::DBI::Abstract::Limit', lazy_build => 1);
has dsn => (is => 'rw', isa => 'ArrayRef', default => sub {
        ['dbi:SQLite:journal.db','','', sqlite_unicode => 1 ]});
has markdown => (
    is => 'rw', isa => 'Text::Markdown', lazy_build => 1, 
    handles => {format_markdown => 'markdown'},
);
#has xatena => (
#    is => 'rw', isa => 'Text::Xatena', lazy_build => 1, 
#    handles => {format_xatena => 'format'},
#);
has tz => ( is => 'ro', isa => 'DateTime::TimeZone', lazy_build => 1 );

sub _build_dbi {
    my $self = shift;
    AnyEvent::DBI::Abstract::Limit->new(@{$self->dsn});
}

#sub _build_xatena { Text::Xatena->new }
sub _build_markdown { Text::Markdown->new }
sub _build_tz { DateTime::TimeZone->new(name => 'local') }

sub format_hatena {
    my ($self, $text) = @_;
    Text::Hatena->parse($text);
}

sub start {
    my $self = shift;
    $self->dbi;
}

sub insert { shift->dbi->insert(@_) }
sub select { shift->dbi->select(@_) }
sub update { shift->dbi->update(@_) }
sub delete { shift->dbi->delete(@_) }

sub inflate {
    my ($self, $row) = @_;
    my $obj = {};
    for (qw(id subject body posted_at format)) {
        $obj->{$_} = shift @$row;
    }
    $obj->{posted_at} = DateTime->from_epoch(
        epoch => $obj->{posted_at},
        time_zone => $self->tz,
    );
    if (my $format = $obj->{format}) {
        my $formater = 'format_' . $format;
        $obj->{html} = $self->$formater($obj->{body});
    }
    return $obj;
}

1;
