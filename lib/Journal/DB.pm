package Journal::DB; 
use 5.12.0;
use DBI;
use SQL::Abstract::Limit;

sub new {
    my ($class, $dsn) = @_;
    $dsn or die 'dsn needed';
    my $self = bless {}, $class;
    $self->{dbh} = DBI->connect(@$dsn)
        or return;
    $self->{sql} = SQL::Abstract::Limit->new(limit_dialect => $self->{dbh});
    return $self;
}

for my $method (qw(insert update delete)) {
    no strict 'refs';
    *{$method} = sub {
        my ($self, @args) = @_;
        my ($stmt, @bind) = $self->{sql}->$method(@args);
        $self->{dbh}->do($stmt, {}, @bind);
    }
}

sub select {
    my ($self, @args) = @_;
    my ($stmt, @bind) = $self->{sql}->select(@args);
    $self->{dbh}->selectall_arrayref($stmt, {Slice => {}}, @bind);
}

sub find {
    my ($self, @args) = @_;
    my ($stmt, @bind) = $self->{sql}->select(@args);
    $self->{dbh}->selectrow_hashref($stmt, {}, @bind);
}

sub max {
    my ($self, $table, $col) = @_;
    my ($stmt) = $self->{sql}->select($table, "max($col) as max");
    return $self->{dbh}->selectrow_hashref($stmt)->{max};
}

1;
