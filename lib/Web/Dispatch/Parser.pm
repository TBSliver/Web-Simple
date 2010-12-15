package Web::Dispatch::Parser;

sub DEBUG () { 0 }

BEGIN {
  if ($ENV{WEB_DISPATCH_PARSER_DEBUG}) {
    no warnings 'redefine';
    *DEBUG = sub () { 1 }
  }
}

use Sub::Quote;
use Web::Dispatch::Predicates;
use Moo;

has _cache => (
  is => 'lazy', default => quote_sub q{ {} }
);

sub diag { if (DEBUG) { warn $_[0] } }

sub _blam {
  my ($self, $error) = @_;
  my $hat = (' ' x (pos||0)).'^';
  die "Error parsing dispatch specification: ${error}\n
${_}
${hat} here\n";
}

sub parse {
  my ($self, $spec) = @_;
  $spec =~ s/\s+//g; # whitespace is not valid
  return $self->_cache->{$spec} ||= $self->_parse_spec($spec);
}

sub _parse_spec {
  my ($self, $spec, $nested) = @_;
  for ($_[1]) {
    my @match;
    PARSE: { do {
      push @match, $self->_parse_spec_section($_)
        or $self->_blam("Unable to work out what the next section is");
      if (/\G\)/gc) {
        $self->_blam("Found closing ) with no opening (") unless $nested;
        last PARSE;
      }
      last PARSE if (pos == length);
      $match[-1] = $self->_parse_spec_combinator($_, $match[-1])
        or $self->_blam('No valid combinator - expected + or |');
    } until (pos == length) }; # accept trailing whitespace
    if ($nested and pos == length) {
      pos = $nested - 1;
      $self->_blam("No closing ) found for opening (");
    }
    return $match[0] if (@match == 1);
    return match_and(@match);
  }
}

sub _parse_spec_combinator {
  my ($self, $spec, $match) = @_;
  for ($_[1]) {

    /\G\+/gc and
      return $match;

    /\G\|/gc and
      return do {
        my @match = $match;
        PARSE: { do {
          push @match, $self->_parse_spec_section($_)
            or $self->_blam("Unable to work out what the next section is");
          last PARSE if (pos == length);
          last PARSE unless /\G\|/gc; # give up when next thing isn't |
        } until (pos == length) }; # accept trailing whitespace
        return match_or(@match);
      };
  }
  return;
}

sub _parse_spec_section {
  my ($self) = @_;
  for ($_[1]) {

    # GET POST PUT HEAD ...

    /\G([A-Z]+)/gc and
      return $self->_http_method_match($_, $1);

    # /...

    /\G(?=\/)/gc and
      return $self->_url_path_match($_);

    # .* and .html

    /\G\.(\*|\w+)/gc and
      return $self->_url_extension_match($_, $1);

    # (...)

    /\G\(/gc and
      return $self->_parse_spec($_, pos);

    # !something

    /\G!/gc and
      return do {
        my $match = $self->_parse_spec_section($_);
        return sub {
          return {} unless my @discard = $match->(@_);
          return;
        };
      };

    # ?<param spec>
    /\G\?/gc and
      return $self->_parse_param_handler($_, 'query');

    # %<param spec>
    /\G\%/gc and
      return $self->_parse_param_handler($_, 'body');
  }
  return; # () will trigger the blam in our caller
}

sub _http_method_match {
  my ($self, $str, $method) = @_;
  match_method($method);
}

sub _url_path_match {
  my ($self) = @_;
  for ($_[1]) {
    my @path;
    my $end = '';
    PATH: while (/\G\//gc) {
      /\G\.\.\./gc
        and do {
          $end = '(/.*)';
          last PATH;
        };
      push @path, $self->_url_path_segment_match($_)
        or $self->_blam("Couldn't parse path match segment");
    }
    if (@path && !$end) {
      length and $_ .= '(?:\.\w+)?' for $path[-1];
    }
    my $re = '^('.join('/','',@path).')'.$end.'$';
    $re = qr/$re/;
    if ($end) {
      return match_path_strip($re);
    } else {
      return match_path($re);
    }
  }
  return;
}

sub _url_path_segment_match {
  my ($self) = @_;
  for ($_[1]) {
    # trailing / -> require / on end of URL
    /\G(?:(?=[+|\)])|$)/gc and
      return '';
    # word chars only -> exact path part match
    /\G([\w\-]+)/gc and
      return "\Q$1";
    # ** -> capture unlimited path parts
    /\G\*\*/gc and
      return '(.*?[^/])';
    # * -> capture path part
    /\G\*/gc and
      return '([^/]+?)';
  }
  return ();
}

sub _url_extension_match {
  my ($self, $str, $extension) = @_;
  match_extension($extension);
}

sub _parse_param_handler {
  my ($self, $spec, $type) = @_;

  require Web::Simple::ParamParser;
  my $unpacker = Web::Simple::ParamParser->can("get_unpacked_${type}_from");

  for ($_[1]) {
    my (@required, @single, %multi, $star, $multistar, %positional, $have_kw);
    my $pos_idx = 0;
    PARAM: { do {

      # ?:foo or ?@:foo

      my $is_kw = /\G\:/gc;

      # ?@foo or ?@*

      my $multi = /\G\@/gc;

      # @* or *

      if (/\G\*/gc) {

        $self->_blam("* is always named; no need to supply :") if $is_kw;

        $multi ? ($multistar = 1) : ($star = 1);

        $have_kw = 1;

        if ($star && $multistar) {
          $self->_blam("Can't use * and \@* in the same parameter match");
        }
      } else {

        # @foo= or foo= or @foo~ or foo~

        /\G(\w+)/gc or $self->_blam('Expected parameter name');

        my $name = $1;

        # check for = or ~ on the end

        /\G\=/gc
          ? push(@required, $name)
          : (/\G\~/gc or $self->_blam('Expected = or ~ after parameter name'));

        # record the key in the right category depending on the multi (@) flag

        $multi ? ($multi{$name} = 1) : (push @single, $name);

        # record positional or keyword

        $is_kw ? ($have_kw = 1) : ($positional{$name} = $pos_idx++);
      }
    } while (/\G\&/gc) }

    return sub {
      my $raw = $unpacker->($_[0]);
      foreach my $name (@required) {
        return unless exists $raw->{$name};
      }
      my (%p, %done);
      my @p = (undef) x $pos_idx;
      foreach my $name (
        @single,
        ($star
          ? (grep { !exists $multi{$_} } keys %$raw)
          : ()
        )
      ) {
        if (exists $raw->{$name}) {
          if (exists $positional{$name}) {
            $p[$positional{$name}] = $raw->{$name}->[-1];
          } else {
            $p{$name} = $raw->{$name}->[-1];
          }
        }
        $done{$name} = 1;
      }
      foreach my $name (
        keys %multi,
        ($multistar
          ? (grep { !exists $done{$_} && !exists $multi{$_} } keys %$raw)
          : ()
        )
      ) {
        if (exists $positional{$name}) {
          $p[$positional{$name}] = $raw->{$name}||[];
        } else {
          $p{$name} = $raw->{$name}||[];
        }
      }
      $p[$pos_idx] = \%p if $have_kw;
      return ({}, @p);
    };
  }
}

1;
