package Journal;
use strict;
use 5.008_001;
our $VERSION = '0.01';

use Tatsumaki::Application;
use Journal::Handlers;
use Journal::DB;

sub handler {
    my ($class, $config) = @_;
    my $db = Journal::DB->new($config || {} );
    my $app = Tatsumaki::Application->new(Journal::Handlers->all);
    $app->add_service(db => $db);
    $app->psgi_app;
}

1;
