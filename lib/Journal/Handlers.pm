package Journal::Handlers;
use strict;
use warnings;
use utf8;
use Journal::View;

sub all {
    my $class = shift;
    return [
        '^/feed$' => 'Journal::Handler::Feed',
        '^/entry/(\d+)' => 'Journal::Handler::Entry',
        '^/writer(?:/?$|/(\d+))' => 'Journal::Handler::Writer',
        '^/(?:$|page/(\d+))' => 'Journal::Handler::Page',
    ];
}

package Journal::Handler;
use parent 'Tatsumaki::Handler';
use Scalar::Util 'blessed';

# copy from Ark::Plugin::Encoding::Unicode::prepare_encoding 
sub prepare {
    my $self = shift;
    my $req  = $self->request;

    my $encode = sub {
        my ($p, $skip) = @_;

        if (blessed $p and $p->isa('Hash::MultiValue')) {
            return if $skip;
            $p->each(sub {
                    utf8::decode($_[1]);
                });
        }
        else {
            # backward compat
            for my $value (values %$p) {
                next if ref $value and ref $value ne 'ARRAY';
                utf8::decode($_) for ref $value ? @$value : ($value);
            }
        }
    };

    $encode->($req->query_parameters);
    $encode->($req->body_parameters);
    $encode->($req->parameters, 1)
};

sub db {
    my $self = shift;
    $self->application->service('db');
}

package Journal::Handler::Entry;
use parent -norequire => 'Journal::Handler';
__PACKAGE__->asynchronous(1);

sub get {
    my ($self, $id) = @_;
    $self->db->select('entry', '*', {id => $id},
        $self->async_cb( sub {
                my ($dbh, $rows, $rv) = @_;
                if ($rows->[0]) {
                    my $entry = $self->db->inflate($rows->[0]);
                    $self->write( 
                        Journal::View->render_layout(
                            'entry', { entry => $entry }
                        ) 
                    );
                } else {
                    Tatsumaki::Error::HTTP->throw(404);
                }
                $self->finish;
            })
    );
}

package Journal::Handler::Writer;
use parent -norequire => 'Journal::Handler';
__PACKAGE__->asynchronous(1);

sub get {
    my ($self, $id) = @_;
    warn $id;
    if ($id) {
        $self->db->select('entry', '*', {id => $id}, 
            $self->async_cb( sub {
                    my ($dbh, $rows, $rv) = @_;
                    my $entry = $self->db->inflate($rows->[0]);
                    $self->write( 
                        Journal::View->render_layout(
                            'writer', { entry => $entry }
                        ) 
                    );
                    $self->finish;
                })
        );
    } else {
        $self->write( 
            Journal::View->render_layout('writer') 
        );
        $self->finish;
    }
}

sub post {
    my ($self, $id) = @_;
    my $params = $self->request->parameters->as_hashref;
    my $delete = delete $params->{delete};
    if ($delete && $id) {
        if ($id) {
            $self->db->delete('entry', {id => $id},
                $self->async_cb(sub {
                        $self->response->redirect("/"); 
                        $self->finish;
                    })
            );
            return;
        } else {
            $self->response->redirect('/writer/' . $id || '');
            $self->finish;
            return;
        }
    }
    unless ($params->{subject} && $params->{body}) {
        $self->response->redirect('/writer/' . $id || '');
        $self->finish;
        return;
    }
    if ($id) {
        $self->db->update('entry', $params, {id => $id},
            $self->async_cb(sub { 
                    $self->response->redirect("/entry/$id"); 
                    $self->finish;
                }
            )
        );
    } else {
        $self->db->insert('entry', 
            {
                %$params, 
                posted_at => time,
            }, 
            $self->async_cb(sub { 
                    my ($dbh, $rows, $rv) = @_;
                    $self->db->select('entry', 'max(id)',
                        $self->async_cb(sub {
                                my ($dbh, $rows, $rv) = @_;
                                my $id = $rows->[0][0];
                                $self->response->redirect("/entry/$id"); 
                                $self->flush;
                            })
                    );
                })
        );
    }
}

package Journal::Handler::Page;
use parent -norequire => 'Journal::Handler';
__PACKAGE__->asynchronous(1);

sub get {
    my ($self, $page) = @_;
    $page ||= 1;
    $self->db->select('entry', '*', undef, {-desc => 'id'}, 10, 10 * ($page - 1),
        $self->async_cb(sub {
                my ($dbh, $rows, $rv) = @_;
                my $entries = [ map {$self->db->inflate($_)} @$rows ];
                $self->write( 
                    Journal::View->render_layout('page', 
                        { page => $page, entries => $entries } 
                    ) 
                );
                $self->finish;
            }
        )
    );
}

package Journal::Handler::Feed;
use parent -norequire => 'Journal::Handler';
__PACKAGE__->asynchronous(1);
use XML::Feed;
use URI::WithBase;

sub get {
    my ($self, $page) = @_;
    $self->db->select('entry', '*', undef, {-desc => 'id'}, 10, 0,
        $self->async_cb(sub {
                my ($dbh, $rows, $rv) = @_;
                my $base = $self->request->base->as_string;
                my $feed = XML::Feed->new('RSS');
                $feed->title('soffritto::journal');
                $feed->description('');
                $feed->link( $base );
                for my $e (map {$self->db->inflate($_)} @$rows) {
                    my $entry = XML::Feed::Entry->new('RSS');
                    $entry->title($e->{subject});
                    $entry->link( 
                        URI::WithBase->new("/entry/$e->{id}", $base)->abs
                    );
                    $entry->content($e->{html});
                    $entry->issued($e->{posted_at});
                    $feed->add_entry($entry);
                }
                $self->write($feed->as_xml);
                $self->finish;
            })
    );
}

1;
