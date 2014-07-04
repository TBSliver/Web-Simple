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
  realclean => { FILES => [ 'Distar/', 'MANIFEST*' ] },
);
