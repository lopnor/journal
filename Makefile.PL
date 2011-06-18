#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Journal',
    AUTHOR => 'Nobuo Danjou <nobuo.danjou@gmail.com>',
    VERSION_FROM => 'lib/Journal.pm',
    ABSTRACT_FROM => 'lib/Journal.pm',
    LICENSE => 'perl',
    MIN_PERL_VERSION => 5.012000,
    PREREQ_PM => {
        'Soffritto::Web' => 0,
        'Text::Markdown' => 0,
        'Text::Hatena' => 0,
        'DateTime' => 0,
        'DateTime::TimeZone' => 0,
        'XML::Feed' => 0,
        'DBD::mysql' => 0,
        'Encode' => 0,
        'Config::Pit' => 0,
        'Plack::Middleware::ReverseProxy' => 0,
    },
);
