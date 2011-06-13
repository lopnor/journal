package Journal::View;
use 5.14.0;
use Markapl;

sub css($) {
    html_link(href => "/static/$_[0]", media => 'screen', rel => 'stylesheet', type => 'text/css');
}

sub js($) {
    script(src => "/static/$_[0]", type => "text/javascript");
}

sub render_layout {
    my ($class, $page, $stash) = @_;
    my $included = $class->render($page, $stash);
    return $class->render('layout', $included, $stash);
}

template 'writer' => sub {
    my ($class, $stash) = @_;
    div {
        form( method => 'POST' ) {
            input( id => 'form_subject', type => 'text', name => 'subject', value => $stash->{entry} ? $stash->{entry}->{subject} : '' );
            textarea( id => 'form_body', name => 'body' ) { $stash->{entry}->{body} || '' };
            input( type => 'submit', value => 'post this entry' );
            input( type => 'submit', name => 'delete', value => 'delete' );
        }
    };
};

template '_entry' => sub {
    my ($class, $stash) = @_;
    my $e = $stash->{entry};
    div(class => 'entry hentry') {
        h2(class => 'subject entry-title') {
            a( rel => 'bookmark', href => '/entry/'.$e->{id} ) { $e->{subject} }
        }
        div(class => 'updated') { $e->{posted_at} }
        div(class => join(' ', 'entry-content', $e->{format})) { 
            outs_raw $e->{html} 
        }
    };
};

template 'entry' => sub {
    my ($class, $stash) = @_;
    outs_raw $class->render('_entry', $stash);
    div(class => 'pager') { 
        a(rel => 'next', href => '/entry/'.($stash->{entry}->{id} - 1)) { 'next' }
    };
};

template 'page' => sub {
    my ($class, $stash) = @_;
    for (@{$stash->{entries}}) {
        outs_raw $class->render('_entry', {entry => $_})
    }
    div(class => 'pager') { 
        a(rel => 'next', href => '/page/'.($stash->{page} + 1)) { 'next' }
    };
};

template 'layout' => sub {
    my ($class, $outs, $stash) = @_;

    html {
        head {
            title { 
                join(' - ', ($stash->{entry}->{subject} || ()), 'soffritto::journal') 
            };
            meta( 'http-equiv' => 'Content-Script-Type', value => 'text/javascript' );
            meta( 'http-equiv' => 'Content-Style-Type', value => 'text/css' );
            html_link( rel => 'alternate', type => 'application/rss+xml', title => 'RSS', href => '/feed' );
            html_link( rel => 'shortcut icon', href => 'http://soffritto.org/images/favicon.ico' );
            css 'style.css';
            js 'jquery.min.js';
            js 'jquery.oembed.js';
            js 'journal.js';
        };
        body {
            div(id => 'header') {
                h1(class => 'title') {
                    a( href => '/' ) { 'soffritto::journal' }
                }
            }
            div(id => 'main', class => 'autopagerize_page_element') { outs_raw $outs }
            div(id => 'footer', class => 'autopagerize_insert_before') { }
        };
    };
};

1;
