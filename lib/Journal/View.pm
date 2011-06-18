package Journal::View;
use 5.12.0;
use Soffritto::Web::Markup;


template 'writer' => sub {
    my ($class, $stash) = @_;
    my $content = [
        form => [ { method => 'POST' },
            input => { id => 'form_subject', type => 'text', name => 'submect',
                value => $stash->{entry}{subject} || '' 
            },
            textarea => [ { id => 'form_body', name => 'body' },
                $stash->{entry}{body}
            ],
            input => { type => 'submit', value => 'post this entry' },
            input => { type => 'submit', name => 'delete', value => 'delete' },
        ],
    ];
    $class->layout($content);
};


template 'entry' => sub {
    my ($class, $stash) = @_;
    my $content = [
        $class->make_entry($stash),
        div => [ { class => 'pager' },
            a => [ { rel => 'next', href => '/entry/'.($stash->{entry}{id} - 1) },
                'next'
            ],
        ]
    ];
    $class->layout($content, $stash->{entry}{subject});
};

template 'page' => sub {
    my ($class, $stash) = @_;
    my $content = [
        map( {$class->make_entry({entry => $_})} @{$stash->{entries}} ),
        div => [ { class => 'pager' },
            a => [ { rel => 'next', href => '/entry/'.($stash->{page} + 1) },
                'next'
            ],
        ]
    ];
    $class->layout($content);
};

sub make_entry {
    my ($class, $stash) = @_;
    my $e = $stash->{entry};
    return (
        div => [ { class => 'entry hentry' },
            h2 => [ { class => 'subject entry-title' },
                a => [ { rel => 'bookmark', href => "/entry/$e->{id}" },  $e->{subject} ]
            ],
            div => [ { class => 'updated' }, $e->{posted_at} ],
            div => [ { class => join(' ', 'entry-content', $e->{format}) },
                $e->{html},
            ]
        ],
    );
};

sub layout {
    my ($class, $content, $title) = @_;

    return [
        html => [
            head => [
                title => join(' - ', $title || (), 'Soffritto::Journal'),
                meta => {
                    'http-equiv' => 'Content-Script-Type',
                    value => 'text/javascript',
                },
                meta => {
                    'http-equiv' => 'Content-Style-Type',
                    value => 'text/css',
                },
                link => {
                    rel => 'alternate', type => 'application/rss+xml', 
                    title => 'RSS', href => '/feed'
                },
                link => { 
                    rel => 'shortcut icon', href => '/static/favicon.ico' 
                },
                link => {
                    rel => 'stylesheet', type => 'text/css', media => 'screen',
                    href => '/static/style.css',
                },
                script => [
                    { type => 'text/javascript', src => '/static/jquery.min.js' }, ''
                ],
                script => [
                    { type => 'text/javascript', src => '/static/jquery.oembed.js' }, ''
                ],
                script => [
                    { type => 'text/javascript', src => '/static/journal.js' }, ''
                ],
            ],
            body => [
                div => [ { id => 'container' },
                    div => [ { id => 'header' },
                        h1 => [ { class => 'title' },
                            a => [ { href => '/' }, 'soffritto::journal' ],
                        ],
                    ],
                    div => [ {id => 'main', class => 'autopagerize_page_element' },
                        @$content,
                    ],
                    div => [ {id => 'footer', class => 'autopagerize_insert_before'},
                        '',
                    ]
                ]
            ],
        ]
    ];
}

1;
