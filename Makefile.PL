use strict;
use warnings FATAL => 'all';
use 5.008001;
use ExtUtils::MakeMaker;

(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

my %WriteMakefileArgs = (
  NAME => 'Web::Simple',
  VERSION_FROM => 'lib/Web/Simple.pm',

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

  META_ADD => {
    prereqs => {
      runtime => {
        requires => {
          'Syntax::Keyword::Gather' => '1.001',
          'Plack' => '0.9968',
          'Moo' => '0.009014',
          'warnings::illegalproto' => '0.001',
          'Data::Dumper::Concise' => '2.020',
          'perl' => '5.006',
        },
      },
    },
  },
  realclean => { FILES => [ 'Distar/', 'MANIFEST*' ] },
);

my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;

for (qw(configure build test runtime)) {
  my $key = $_ eq 'runtime' ? 'PREREQ_PM' : uc $_.'_REQUIRES';
  next unless exists $WriteMakefileArgs{META_ADD}{prereqs}{$_}
           or exists $WriteMakefileArgs{$key};
  my $r = $WriteMakefileArgs{$key} = {
    %{$WriteMakefileArgs{META_ADD}{prereqs}{$_}{requires} || {}},
    %{delete $WriteMakefileArgs{$key} || {}},
  };
  defined $r->{$_} or delete $r->{$_} for keys %$r;
}

# dynamic prereqs get added here.

$WriteMakefileArgs{MIN_PERL_VERSION} = delete $WriteMakefileArgs{PREREQ_PM}{perl} || 0;

$WriteMakefileArgs{BUILD_REQUIRES} = {
    %{$WriteMakefileArgs{BUILD_REQUIRES} || {}},
    %{delete $WriteMakefileArgs{TEST_REQUIRES}}
} if $eumm_version < 6.63_03;

$WriteMakefileArgs{PREREQ_PM} = {
    %{$WriteMakefileArgs{PREREQ_PM}},
    %{delete $WriteMakefileArgs{BUILD_REQUIRES}}
} if $eumm_version < 6.55_01;

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  if $eumm_version < 6.51_03;

WriteMakefile(%WriteMakefileArgs);
