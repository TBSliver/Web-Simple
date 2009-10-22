use strict;
use warnings FATAL => 'all';

use Test::More qw(no_plan);

use Web::Simple::DispatchParser;

my $dp = Web::Simple::DispatchParser->new;

my $get = $dp->parse_dispatch_specification('GET');

is_deeply(
  [ $get->({ REQUEST_METHOD => 'GET' }) ],
  [ {} ],
  'GET matches'
);

is_deeply(
  [ $get->({ REQUEST_METHOD => 'POST' }) ],
  [],
  'POST does not match'
);

ok(
  !eval { $dp->parse_dispatch_specification('GET POST'); 1; },
  "Don't yet allow two methods"
);

my $html = $dp->parse_dispatch_specification('.html');

is_deeply(
  [ $html->({ PATH_INFO => '/foo/bar.html' }) ],
  [ { PATH_INFO => '/foo/bar' } ],
  '.html matches'
);

is_deeply(
  [ $html->({ PATH_INFO => '/foo/bar.xml' }) ],
  [],
  '.xml does not match .html'
);

my $slash = $dp->parse_dispatch_specification('/');

is_deeply(
  [ $slash->({ PATH_INFO => '/' }) ],
  [ {} ],
  '/ matches /'
);

is_deeply(
  [ $slash->({ PATH_INFO => '/foo' }) ],
  [ ],
  '/foo does not match /'
);

my $post = $dp->parse_dispatch_specification('/post/*');

is_deeply(
  [ $post->({ PATH_INFO => '/post/one' }) ],
  [ {}, 'one' ],
  '/post/one parses out one'
);

is_deeply(
  [ $post->({ PATH_INFO => '/post/one/' }) ],
  [],
  '/post/one/ does not match'
);

my $combi = $dp->parse_dispatch_specification('GET+/post/*');

is_deeply(
  [ $combi->({ PATH_INFO => '/post/one', REQUEST_METHOD => 'GET' }) ],
  [ {}, 'one' ],
  '/post/one parses out one'
);

is_deeply(
  [ $combi->({ PATH_INFO => '/post/one/', REQUEST_METHOD => 'GET' }) ],
  [],
  '/post/one/ does not match'
);

is_deeply(
  [ $combi->({ PATH_INFO => '/post/one', REQUEST_METHOD => 'POST' }) ],
  [],
  'POST /post/one does not match'
);
