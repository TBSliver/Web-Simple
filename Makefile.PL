use strict;
use warnings FATAL => 'all';
use 5.008001;
use ExtUtils::MakeMaker;

(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'Web::Simple',
  VERSION_FROM => 'lib/Web/Simple.pm',
  PREREQ_PM => { },
  MIN_PERL_VERSION => '5.006',

  META_MERGE => {
    'meta-spec' => { version => 2 },
    dynamic_config => 0,
    resources => {
      # r/w: p5sagit@git.shadowcat.co.uk:Web-Simple.git
      repository => {
        url => 'git://git.shadowcat.co.uk/p5sagit/Web-Simple.git',
        web => 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=p5sagit/Web-Simple.git',
        type => 'git',
      },
      bugtracker => {
          mailto => 'bug-Web-Simple@rt.cpan.org',
          web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Web-Simple',
      },
    },
    prereqs => {
      runtime => {
        requires => {
          'Carp' => '0',
          'Encode' => '0',
          'Exporter' => '0',
          'File::Glob' => '0',
          'HTTP::Body' => '0',
          'HTTP::Headers' => '0',
          'HTTP::Request' => '0',
          'IO::Handle' => '0',
          'MIME::Base64' => '0',
          'Moo' => '0.009014',
          'Plack' => '0.9968',
          'Scalar::Util' => '0',
          'Sub::Quote' => '0',
          'Syntax::Keyword::Gather' => '1.001',
          'URI' => '0',
          'base' => '0',
          'overload' => '0',
          'strict' => '0',
          'strictures' => '1',
          'warnings' => '0',
          'warnings::illegalproto' => '0',
        },
      },
      test => {
        requires => {
          'Data::Dumper::Concise' => '2.020',
          'HTTP::Request::AsCGI' => '0',
          'HTTP::Request::Common' => '0',
          'HTTP::Response' => '0',
          'Socket' => '0',
          'Test::More' => '0.88',
        },
        recommends => {
          'Devel::Cycle' => '0',
        },
      },
    },
  },

  realclean => { FILES => [ 'Distar/', 'MANIFEST*' ] },
);
