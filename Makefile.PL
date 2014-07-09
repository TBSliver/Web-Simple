use strict;
use warnings FATAL => 'all';
use 5.008001;
use ExtUtils::MakeMaker;

(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'Web::Simple',
  VERSION_FROM => 'lib/Web/Simple.pm',
  PREREQ_PM => {
    'Syntax::Keyword::Gather' => '1.001',
    'Plack' => '0.9968',
    'Moo' => '0.009014',
    'warnings::illegalproto' => '0.001',
    'Data::Dumper::Concise' => '2.020',
  },
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
  },

  realclean => { FILES => [ 'Distar/', 'MANIFEST*' ] },
);
