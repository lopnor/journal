use 5.14.0;
use lib 'lib';
use Journal;
use Plack::Builder;
use Config::Pit;

my $config = pit_get('journal.soffritto.org') or die;
my $dsn = delete $config->{dsn} or die 'dsn not defined';

my $app = Journal->new(dsn => $dsn)->to_app;

builder {
    enable 'ReverseProxy';
    enable 'Static', path => qr{^/static/};
    enable_if { 
        $_[0]->{SCRIPT_NAME}.$_[0]->{PATH_INFO} =~ m{^/writer} 
    } 'Auth::Basic', authenticator => \&authen_cb;
    $app;
};

sub authen_cb {
    my ($username, $password) = @_;
    return $username eq $config->{username} && $password eq $config->{password};
}
