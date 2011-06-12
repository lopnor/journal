use inc::Module::Install;
name 'Journal';
all_from 'lib/Journal.pm';
requires 'Tatsumaki';
requires 'AnyEvent::DBI::Abstract::Limit';
requires 'DBD::mysql';
requires 'Markapl';
requires 'Config::Pit';
requires 'Text::Markdown';
requires 'Text::Hatena';
requires 'Any::Moose';
requires 'Scalar::Util';
requires 'URI::WithBase';
requires 'XML::Feed';
requires 'DateTime';
requires 'DateTime::TimeZone';
requires 'parent';

build_requires 'Test::More';

tests 't/*.t';

auto_include;
auto_set_repository;
WriteAll;
